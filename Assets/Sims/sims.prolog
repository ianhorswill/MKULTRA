:- dynamic visited/2.

handle_event(next_action(null), Action) :-
    best_action(Action).
handle_event(Event, Action) :-
    begin(notify_activities(Event),
	  best_action(Action)).
%% handle_event(collision(What), say("Sorry!")) :-
%%     character(What).
%% handle_event(collision(_What), say("oops!")).

best_action(Action) :-
    arg_max(Action,
	    Score,
	    (  available_action(Action),
	       action_score(Action, Score)  )).

notify_activities(Event) :-
    forall(activity(Activity, Type),
	   ignore(on_event(Type, Activity, Event))).

available_action(Action) :-
    activity(Activity, Type),
    propose_action(Type, Activity, Action).

action_score(Action, TotalScore) :-
    sumall(Score,
	   ( activity(Activity, Type),
	     score_action(Type, Activity, Action, Score) ),
	   TotalScore).

prop(GameObject) :-
    % An object is a prop if it has a DockingRegion component.
    component_of_gameobject_with_type(_Component, GameObject, $dockingregion).

character(GameObject) :-
    % An object is a character if it has a SimController component.
    component_of_gameobject_with_type(_Component, GameObject, $simcontroller).

world_object(WorldObject) :-
    prop(WorldObject) ; character(WorldObject).

% GameObject is the nearest object satisfying Constraint.
nearest(GameObject, Constraint) :-
    arg_min(GameObject,
	    Distance,
	    (Constraint, Distance is distance(GameObject, $game_object))).

actions :-
    forall( ( available_action(A), 
	      action_score(A, S) ),
	    ( write(A), write("\t"), writeln(S) )).

initialize :-
    (prop(P), assert(/visit_time/P:0), fail) ; true.

:- initialize.


