:- dynamic visited/2.

handle_event(next_action(null), Action) :-
    best_action(Action).
handle_event(arrived_at(Place), Action) :-
    on_arrived_at(Place),
    best_action(Action).
handle_event(collision(What), say("Sorry!")) :-
    character(What).
handle_event(collision(_What), say("oops!")).

best_action(Action) :-
    arg_max(Action,
	    Score,
	    (  available_action(Action),
	       action_score(Action, Score)  )).

action_score(Action, Score) :-
    sumall(CScore, critique_action(Action, CScore), Score).

available_action(goto(Prop)) :-
    prop(Prop).

critique_action(goto(Prop), Score) :-
    Score is -distance(Prop, $game_object).
critique_action(goto(Prop), Score) :-
    time_since_visit(Prop, Score) -> true ; Score = 100.

on_arrived_at(Prop) :-
    Now is $now, assert(/visit_time/Prop:Now).

time_since_visit(Prop, ElapsedTime) :-
    /visit_time/Prop:VisitTime,
    ElapsedTime is $now - VisitTime.

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

initialize :-
    (prop(P), assert(/visit_time/P:0), fail) ; true.

:- initialize.


