%%%
%%% ACTION SELECTION
%%%
%%% Main idea:
%%% - SimController calls next_action/1
%%% - Concerns propose actions using propose_action/3.
%%% - Concerns can score and action or one its construals through score_action/4.
%%% - Score for an action is sum of all scores by all concerns of all construals
%%% - Select action with maximal score.
%%%

:- public actions/0, next_action/1, score_action/4.

%% propose_action(-Action, +Type, +Concern)
%  Concern, which is of type Type, proposes Action.
:- external propose_action/3.

%% action_score(+Action, +Type, +Concern, -Score) is nondet
%  Concern (of type Type) assigns Score to Action.
:- external action_score/4.

%% next_action(-Action) is det
%  Action is the highest rated action available, or sleep if no available actions.
%  Called by SimController component's Update routine.
next_action(Action) :-
   tick_tasks,
   best_action(Action).
next_action(sleep(1)).

best_action(Action) :-
   ignore(retract(/action_state/candidates)),
   arg_max(Action,
	   Score,
	   (  generate_unique(Action, available_action(Action)),
	      runnable(Action),
	      action_score(Action, Score),
	      assert(/action_state/candidates/Action:Score) )).

available_action(Action) :-
   concern(Concern, Type),
   propose_action(Action, Type, Concern).

action_score(Action, TotalScore) :-
   sumall(Score,
	  ( generate_unique(Construal, construal(Action, Construal)),
	    concern(Concern, Type),
	    score_action(Action, Type, Concern, Score) ),
	  TotalScore).

actions :-
   findall(S-A,
	   ( available_action(A), 
	     action_score(A, S) ),
	   Unsorted),
   keysort(Unsorted, Sorted),
   reverse(Sorted, Reversed),
   forall(member(Score-Action, Reversed),
	  ( write(Action), write("\t"), writeln(Score) )).
