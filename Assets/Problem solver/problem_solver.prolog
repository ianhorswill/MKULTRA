%%
%% Simple problem solver in the general tradition of NASL
%%

test_file(problem_solver(_), "Problem solver/ps_tests").

% Problem solver state is stored in:
%   TaskConcern/type:task:TopLevelTask         
%   TaskConcern/current:CurrentStep     (always an action or polled_builtin)
%   TaskConcern/continuation:Task       (any task)

:- indexical task=null.

:- external veto_strategy/1.

%% within_task(+TaskConcern, :Code)
%  Runs Code within the task TaskConcern.
within_task(TaskConcern, Code) :-
   bind(task, TaskConcern),
   (TaskConcern/partner/P -> bind(addressee, P) ; true),
   Code.

% Ontology:
% event => task
% task => compound_task | primitive_task
% compound_task => simple_compound_task | (task, task) | let(PrologCode, task)
% primitive_task => builtins | actions
% builtins => immediate_builtin | polled_builtin | wait_event_with_timeout(Event, TimeoutPeriod)
% immediate_builtin => null | done | call(PrologCode) | assert(Fact) | retract(Fact) | invoke_continuation(K)
% polled_builtin => wait_condition(PrologCode) | wait_event(Event) | wait_event(Event, Deadline). 
%
% Primitives are executable, compound tasks need to be decomposed using
% strategies, which map simple compound tasks to other tasks.

% primitive_task(T) :-
%    builtin_task(T) ; action(T).
% builtin_task(T) :-
%    immediate_builtin(T) ; polled_builtin(T).
% immediate_builtin(null).
% immediate_builtin(done).
% immediate_builtin(call(_)).
polled_builtin(wait_condition(_)).
polled_builtin(wait_event(_)).
polled_builtin(wait_event(_,_)).

%% strategy(+Task, -CandidateStrategy)
%  CandidateStrategy is a possible way to solve Task.
%  CandidateStrategy may be another task, null, or a sequence of tasks
%  constructed using ,/2.

%%
%% Interface to external code
%% Task creation, strategy specification
%%

:- public start_task/5, start_task/3, start_task/2.

%% start_task(+Parent, +Task, +Priority, TaskConcern, +Assertions) is det
%  Adds a task to Parent's subconcerns.  Priority is
%  The score to be given by the task to any actions it attempts
%  to perform.
start_task(Parent, Task, Priority, TaskConcern, Assertions) :-
   begin_child_concern(Parent, task, Priority, TaskConcern,
		       [TaskConcern/type:task:Task,
			TaskConcern/continuation:done]),
   forall(member(A, Assertions),
	  assert(A)),
   within_task(TaskConcern, switch_to_task(Task)).

start_task(Parent, Task, Priority) :-
   start_task(Parent, Task, Priority, _, [ ]).
start_task(Task, Priority) :-
   start_task($root, Task, Priority, _, [ ]).

:- external trace_task/1.

%% switch_to_task(+Task)
%  Stop running current step and instead run Task followed by our continuation.
%  If Task decomposes to a (,) expression, this will update both current and
%  continuation, otherwise just current.

% Check for immediate builtins
switch_to_task(Task) :-
   assert($task/log/Task),
   trace_task(Task),
   ($task/current:CurrentStep ->
      ($task/continuation:K ->
           log($me:(CurrentStep -> (Task, K)))
           ;
           log($me:(CurrentStep -> Task)))
      ;
      log($me:(null->Task))),
   fail.
switch_to_task(done) :-
   kill_concern($task).
switch_to_task(null) :-
   step_completed.
switch_to_task(call(PrologCode)) :-
   begin(PrologCode,
	 step_completed).
switch_to_task(assert(Fact)) :-
   begin(assert(Fact),
	 step_completed).
switch_to_task(retract(Fact)) :-
   begin(retract(Fact),
	 step_completed).
switch_to_task(invoke_continuation(K)) :-
   invoke_continuation(K).

% Non-immediates that can be taken care of now.
switch_to_task(wait_condition(Condition)) :-
   Condition,
   !,
   step_completed.
switch_to_task( (First, Rest) ) :-
   begin($task/continuation:K,
	 assert($task/continuation:(Rest,K)),
	 switch_to_task(First)).
switch_to_task(let(BindingCode, Task)) :-
   BindingCode ->
      switch_to_task(Task)
      ;
      throw(let_failed(let(BindingCode, Task))).

% All other primitive tasks
switch_to_task(wait_event_with_timeout(E, TimeoutPeriod)) :-
   % Translate wait_event_with_timeout into wait_event/2,
   % which has a deadline rather than a timeout period.
   Deadline is $now + TimeoutPeriod,
   switch_to_task(wait_event(E, Deadline)).
switch_to_task(B) :-
   polled_builtin(B),
   !,
   assert($task/current:B).
switch_to_task(A) :-
   action(A),
   !,
   (blocking(A, Precondition) ->
      % Oops, can't run action yet because of blocked precondition.
      switch_to_task( (achieve(Precondition),A) )
      ;
      % It's an action and it's ready to run.
      assert($task/current:A:action)).

% Simple compound task, so decompose it.
switch_to_task(Task) :-
   !,
   begin(matching_strategies(Strategies, Task),
	 select_strategy(Task, Strategies)).

matching_strategies(Strategies, Task) :-
   all(S,
       matching_strategy(S, Task),
       Strategies).

matching_strategy(S, Task) :-
   strategy(Task, S),
   \+ veto_strategy(Task).

%% select_strategy(+Step, StrategyList)
%  If StrategyList is a singleton, it runs it, else subgoals
%  to a metastrategy.

select_strategy(_, [S]) :-
   begin(switch_to_task(S)).
select_strategy(resolve_match_failure(resolve_match_failure(resolve_match_failure(X))), []) :-
   kill_concern($task),
   throw(repeated_match_failure(X)).
select_strategy(Task, [ ]) :-
   begin(switch_to_task(resolve_match_failure(Task))).
select_strategy(Task, Strategies) :-
   begin(switch_to_task(resolve_conflict(Task, Strategies))).

%% step_completed
%  Current task has completed its current step; run continuation.
step_completed :-
   $task/continuation:K,
   invoke_continuation(K).

%% step_completed(+TaskConcern)
%  TaskConcern has completed its current step; tell it to run
%  its comtinuation.
step_completed(TaskConcern) :-
   within_task(TaskConcern, step_completed).

%% invoke_continuation(+Task)
%  Switch to current task's continuation, which is Task.
invoke_continuation( (First, Rest) ) :-
   !,
   begin(assert($task/continuation:Rest),
	 switch_to_task(First)).
invoke_continuation(K) :-
   begin(assert($task/continuation:done),
	 switch_to_task(K)).

%%
%% Driver code - called from action_selection.prolog
%%

%% poll_tasks
%  Polls all tasks of all concerns.
poll_tasks :-
   forall(concern(Task, task),
	  poll_task(Task)).

%% poll_task(+Task)
%  Attempts to make forward progress on Task's current step.
poll_task(T) :-
   (T/current:A)>>ActionNode,
   ((ActionNode:action) ->
      poll_action(T, A)
      ;
      poll_builtin(T, A)).

poll_action(T, A) :-
   % Make sure it's still runnable
   runnable(A) ; interrupt_step(T, achieve(runnable(A))).

poll_builtin(T, wait_condition(Condition)) :-
   !,
   (Condition -> step_completed(T) ; true).
poll_builtin(_, wait_event(_)).   % nothing to do.
poll_builtin(T, wait_event(_, Timeout)) :-
   ($now > Timeout) ->
      step_completed(T) ; true.

%%
%% Interrupts
%%

%% interrupt_step(TaskConcern, +InterruptingTask)
%  Executes InterruptingTask, then returns to previous step.
interrupt_step(TaskConcern, InterruptingTask) :-
   within_task(TaskConcern,
	       begin(TaskConcern/current:C,
		     TaskConcern/continuation:K,
		     assert(TaskConcern/continuation:(C,K)),
		     switch_to_task(InterruptingTask))).

%%
%%  Interface to mundane action selection
%%

propose_action(A, task, T) :-
   T/current:A:action.

score_action(A, task, T, Score) :-
   T/current:X:action,
   A=X,
   T/priority:Score.

on_event(E, task, T, step_completed(T)) :-
   T/current:X,
   (X=E ; X=wait_event(E) ; X=wait_event(E,_)).
