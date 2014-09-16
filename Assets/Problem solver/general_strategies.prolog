%%
%% General strategies
%%

%% default_strategy(+Task, -Strategy) is nondet
%  Provides default strategies to use when Task has no specific matches.
strategy(resolve_match_failure(X), S) :-
   default_strategy(X, S).

%%
%% achieve(P)
%% Task to make P become true.
%%

strategy(achieve(P),
	 Task) :-
   postcondition(Task, P).

strategy(achieve(Condition),
	 null) :-
   % Don't have to do anything if condition is already true.
   Condition,
   !.

strategy(achieve(runnable(Action)),
	 achieve(Blocker)) :-
   blocking(Action, Blocker),
   \+ unachievable(Blocker).

%% unachievable(+Task)
%  Task is a-priori unachievable, so give up.
unachievable(exists(_)).

strategy(achieve(P),
	 wait_condition(P)) :-
   self_achieving(P).

%%
%% MOVEMENT AND LOCOMOTION
%% achieving locations
%% moving
%% docking
%% goto
%%

strategy(achieve(location(X,$me)),
	 pickup(X)).
strategy(achieve(location(X, Room)),
	 achieve(location(X, Container))) :-
   %\+ freestanding(X),
   is_a(Room, room),
   is_a(Container, work_surface),
   location(Container, Room).
strategy(achieve(location(X, Container)),
	 putdown(X, Container)) :-
   Container \= $me,
   \+ is_a(Container, room).

strategy(move($me, X,Y),
	 achieve(location(X, Y))).

strategy(achieve(docked_with(WorldObject)),
	 goto(WorldObject)).
strategy(goto(Object),
	 ( let(top_level_container(Object, Place),
	       ( assert($task/location_bids/Place:Priority),
		 wait_event(arrived_at(Place)),
		 retract($task/location_bids/Place)) ) )) :-
   $task/priority:Priority.

%%
%% Ingestion (eating and drinking)
%%

strategy(eat($me, X),
	 ingest(X)).
postcondition(eat(_, X),
	      ~exists(X)).
postcondition(eat(Person, F),
	      ~hungry(Person)) :-
   existing(food, F).

strategy(drink($me, X),
	 ingest(X)).
postcondition(drink(_, X),
	      ~exists(X)).
postcondition(drink(Person, B),
	      ~thirsty(Person)) :-
   existing(beverage, B).

self_achieving(/perception/nobody_speaking).

%%
%% OTHER
%% Sleeping
%%

strategy(sleep(Seconds),
	 wait_condition(after_time(Time))) :-
   Time is $now + Seconds.

