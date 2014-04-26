notify_event(Event) :-
    forall(concern(Concern, Type),
	   ignore(on_event(Type, Concern, Event))).

next_action(Action) :-
    best_action(Action).
next_action(sleep(1)).

best_action(Action) :-
    ignore(retract(/action_state/candidates)),
    arg_max(Action,
	    Score,
	    (  available_action(Action),
	       action_score(Action, Score),
	       copy_term(Action,Copy),
	       assert(/action_state/candidates/Copy:Score) )).

available_action(Action) :-
    /action_state/propose_once/Stored, copy_term(Stored, Action).
available_action(Action) :-
    ignore(retract(/action_state/propose_once)),
    concern(Concern, Type),
    propose_action(Type, Concern, Action).

action_score(Action, TotalScore) :-
    sumall(Score,
	   ( concern(Concern, Type),
	     score_action(Type, Concern, Action, Score) ),
	   TotalScore).

propose_once(Action) :-
    copy_term(Action, Copy), assert(/action_state/propose_once/Copy).

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
    findall(S-A,
	    ( available_action(A), 
	      action_score(A, S) ),
	    Unsorted),
    keysort(Unsorted, Sorted),
    reverse(Sorted, Reversed),
    forall(member(Score-Action, Reversed),
	   ( write(Action), write("\t"), writeln(Score) )).


