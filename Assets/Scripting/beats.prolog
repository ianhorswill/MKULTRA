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

:- external beat/1, beat_precondition/2, beat_start_task/3, beat_idle_task/3.
:- higher_order beat_precondition(0, 1).
:- public task_advances_current_beat/1, my_beat_idle_task/1.

%%%
%%% Task generation based on beat
%%%
%%% This code gets called by characters when they're idle to find out
%%% they can do to advance the plot.
%%%
%%% There are two different entrypoints, one for dialog tasks and
%%% one for non-dialog tasks.
%%%

%% task_advances_current_beat(-Task) is det
%  Task is the thing I should run to try to move the beat forward.
%  If I'm not a participant for this beat or if there's nothing for me
%  to do right now, this will fail.
task_advances_current_beat(begin(Task,
				 assert($global_root/beats/Beat/completed_tasks/Task))) :-
   current_beat(Beat),
   task_advances_beat(Beat, Task).

%% task_advances_beat(+Beat, -Task)
%  Task is a task I can do that would advance Beat.
task_advances_beat(Beat, Task) :-
   beat_participant(Beat, $me),
   ( next_beat_task(Beat, T) ->
        can_perform_beat_task(T, Task)
        ;
        (Task=null, check_beat_completion) ).

can_perform_beat_task(Who:Task, Task) :-
   !,
   Who = $me.
can_perform_beat_task(Task, Task) :-
   have_strategy(Task).

next_beat_task(Beat, Task) :-
   beat_tasks(Beat, TaskList),
   member(Task, TaskList),
   \+ $global_root/beats/Beat/completed_tasks/Task.


%% my_beat_idle_task(-Task)
%  Task is the thing I should do to advance the current beat if
%  I'm not already involved in dialog.
my_beat_idle_task(Task) :-
   \+ in_conversation_with(_),  % we're not idle if we aren't in conversation
   current_beat(Beat),
   beat_idle_task(Beat, $me, Task).

%%%
%%% Beat selection
%%%

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
   log(beat:Beat),
   assert($global_root/beats/current:Beat),
   set_beat_state(Beat, started).

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
   set_current_beat(Beat),
   start_beat(Beat).

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

start_beat(Beat) :-
   forall(beat_start_task(Beat, Who, Task),
	  Who::add_pending_task(Task)).

check_beat_completion :-
   current_beat(Beat),
   (beat_completion_condition(Beat, C) -> C ; true),
   end_beat.

end_beat :-
   current_beat(Beat),
   log(Beat:completed),
   set_beat_state(Beat, completed),
   retract($global_root/beats/current).

test_file(problem_solver(_),
	  "Scripting/beat_task_crossrefs").

%%%
%%% Exposition beat
%%%

beat(exposition).
beat_participant(exposition, $bruce).
beat_participant(exposition, $kavi).
beat_start_task(exposition,
		$kavi,
		goto($bruce)).
beat_tasks(exposition,
	   [ mention_macguffin,
	     mention_keepout ]).

%%%
%%% Bruce explores the house
%%%

beat(bruce_explores_the_house).
beat_participant(bruce_explores_the_house, $bruce).
beat_start_task(bruce_explores_the_house,
		$kavi,
		goto($'kitchen sink')).
beat_completion_condition(bruce_explores_the_house,
			  ( $bruce::contained_in($macguffin, $bruce),
			    $bruce::contained_in($report, $bruce) )).
beat_idle_task(bruce_explores_the_house,
	       $bruce,
	       search_for($bruce, kavis_house, _)).