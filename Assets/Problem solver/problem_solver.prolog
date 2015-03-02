%%
%% Simple problem solver in the general tradition of NASL
%%

test_file(problem_solver(_), "Problem solver/integrity_checks").
test_file(problem_solver(_), "Problem solver/ps_tests").

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


% Problem solver state is stored in:
%   TaskConcern/type:task:TopLevelTask         
%   TaskConcern/current:CurrentStep     (always an action or polled_builtin)
%   TaskConcern/continuation:Task       (any task)

:- indexical task=null.

:- external veto_strategy/1, personal_strategy/2, before/2, after/2.

%% within_task(+TaskConcern, :Code)
%  Runs Code within the task TaskConcern.
within_task(TaskConcern, Code) :-
   bind(task, TaskConcern),
   (TaskConcern/partner/P -> bind(addressee, P) ; true),
   Code.

primitive_task(T) :-
   builtin_task(T) ; action(T).
builtin_task(T) :-
   immediate_builtin(T) ; polled_builtin(T).
immediate_builtin(null).
immediate_builtin(done).
immediate_builtin(call(_)).
immediate_builtin(assert(_)).
immediate_builtin(retract(_)).
immediate_builtin(invoke_continuation(_)).
immediate_builtin((_,_)).
immediate_builtin(let(_,_)).
polled_builtin(wait_condition(_)).
polled_builtin(wait_event(_)).
polled_builtin(wait_event(_,_)).

%% strategy(+Task, -CandidateStrategy)
%  CandidateStrategy is a possible way to solve Task.
%  CandidateStrategy may be another task, null, or a sequence of tasks
%  constructed using ,/2.

%% personaly_strategy(+Task, -CandidateStrategy)
%  CandidateStrategy is a possible way to solve Task.
%  CandidateStrategy may be another task, null, or a sequence of tasks
%  constructed using ,/2.

:- external trace_task/2.

%% switch_to_task(+Task)
%  Stop running current step and instead run Task followed by our continuation.
%  If Task decomposes to a (,) expression, this will update both current and
%  continuation, otherwise just current.

switch_to_task(Task) :-
   % This clause just logs Task and fails over to the next clause.
   assert($task/log/Task),
   emit_grain("task", 10),
   trace_task($me, Task),
   ($task/current:CurrentStep ->
      ($task/continuation:K ->
           log($me:(CurrentStep -> (Task, K)))
           ;
           log($me:(CurrentStep -> Task)))
      ;
      log($me:(null->Task))),
   fail.
% Check for immediate builtins
switch_to_task(done) :-
   $task/repeating_task ->
      ( $task/type:task:Goal, invoke_continuation(Goal) )
      ;
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

%% We have a task we don't know what to do with.
switch_to_task(resolve_match_failure(resolve_match_failure(resolve_match_failure(FailedTask)))) :-
   $task/type:task:TopLevelTask,
   asserta($global::failed_task($me, (TopLevelTask-> FailedTask))),
   emit_grain("task fail", 100),
   kill_concern($task),
   throw(repeated_match_failure($me, (TopLevelTask->FailedTask))).

% Simple compound task, so decompose it.
switch_to_task(Task) :-
   !,
   begin(task_reduction(Task, Reduced),
	 switch_to_task(Reduced)).

%% have_strategy(+Task)
%  True when we have at least some candidate reduction for this task.
have_strategy(Task) :-
%   once(matching_strategy(_, Task)).
   task_reduction(Task, Reduct),
   !,
   Reduct \= resolve_match_failure(_).

:- public show_decomposition/1.
   
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
