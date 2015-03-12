%%%
%%% Simple Beat system
%%% Doesn't handle joint dialog behaviors, since problem solver doesn't support
%%% joint behaviors in general
%%%

%%
%% Since the beat system operates at the story level rather than the
%% character level, its state information is stored in
%% $global_root/beats rather than in a specific character.  However,
%% there is no global drama manager object, so beat selection code
%% runs in whatever character happens to run code that needs to select
%% a new beat.
%%

:- external beat/1, beat_precondition/2.
:- higher_order beat_precondition(0, 1).
:- public task_advances_current_beat/1.

task_advances_current_beat(begin(Task,
				 assert($global_root/beats/Beat/completed_tasks/Task))) :-
   current_beat(Beat),
   task_advances_beat(Beat, Task).

%% task_advances_beat(+Beat, -Task)
%  Task is a task I can do that would advance Beat.
task_advances_beat(Beat, Task) :-
   beat_tasks(Beat, TaskList),
   member(Task, TaskList),
   \+ $global_root/beats/Beat/completed_tasks/Task,
   !,  % Just take the first uncompleted task.
   have_strategy(Task),
   !.

%% current_beat(?Beat)
%  Beat is the beat we're currently working on.  If none had been
%  previously selected, this will force it to select a new one.
current_beat(Beat) :-
   $global_root/beats/current:Beat,
   !.
current_beat(Beat) :-
   var(Beat), % need this or calling this will a bound variable
              % will force the selection of a new beat.
   select_new_beat(Beat),
   !.

set_current_beat(Beat) :-
   assert($global_root/beats/current:Beat).

%% beat_state(?Beat, ?State)
%  Beat is in the specified State.
beat_state(Beat, State) :-
   $global_root/beats/Beat/state:State.
set_beat_state(Beat, State) :-
   assert($global_root/beats/Beat/state:State).

%% best_next_beat(-Beat)
%  Beat is the best beat to run next.
best_next_beat(Beat) :-
   arg_max(Beat,
	   Score,
	   ( available_beat(Beat),
	     beat_score(Beat, Score) )).

%% select_new_beat(-Beat)
%  Forces reselection of the next beat.
select_new_beat(Beat) :-
   best_next_beat(Beat),
   set_current_beat(Beat).

%% available_beat(?Beat)
%  Beat is a beat that hasn't finished and whose preconditions are satisfied.
available_beat(Beat) :-
   beat(Beat),
   \+ beat_state(Beat, completed),
   runnable_beat(Beat).

%% runnable_beat(+Beat)
%  Beat has no unsatisfied preconditions
runnable_beat(Beat) :-
   forall(beat_precondition(Beat, P),
	  P).

%% beat_score(+Beat, -Score)
%  Beat has the specified score.
beat_score(_Beat, 0).

%%%
%%% Exposition beat
%%%

beat(exposition).
beat_tasks(exposition,
	   [ mention_macguffin,
	     mention_keepout,
	     $kavi:goto($'kitchen sink') ]).