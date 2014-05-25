:- public notify_event/1, 
    world_object/1, nearest/2,
	actions/0, next_action/1, propose_once/1,
    do_all_character_initializations/0. 
:- external propose_action/3.
:- higher_order on_event(0, 0, 0, 1).

notify_event(Event) :-
    findall(Handler,
	    (concern(Concern, Type),
	     on_event(Type, Concern, Event, Handler)),
	    Handlers),
    forall(member(Handler, Handlers),
	   (Handler -> true ; log(handler_failed(Handler)))).

next_action(Action) :-
    best_action(Action).
next_action(sleep(1)).

best_action(Action) :-
    ignore(retract(/action_state/candidates)),
    arg_max(Action,
	    Score,
	    (  available_action(Action),
	       action_score(Action, Score),
	       assert(/action_state/candidates/Action:Score) )).

available_action(Action) :-
    /action_state/propose_once/Action.
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
    assert(/action_state/propose_once/Action).

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

% Called once by SimController.Start()
do_all_character_initializations :-
    (character_initialization, fail) ; true.


