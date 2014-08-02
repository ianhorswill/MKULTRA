%%
%% General strategies
%%

strategy(achieve(Condition),
	 null) :-
   % Don't have to do anything if condition is already true.
   Condition,
   !.

strategy(achieve(runnable(Action)),
	 achieve(Blocker)) :-
   blocking(Action, Blocker).

strategy(achieve(P),
	 wait_condition(P)) :-
   self_achieving(P).

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

strategy(eat($me, X),
	 ingest(X)).

strategy(drink($me, X),
	 ingest(X)).

self_achieving(/perception/nobody_speaking).

strategy(sleep(Seconds),
	 wait_condition(after_time(Time))) :-
   Time is $now + Seconds.

strategy(achieve(docked_with(WorldObject)),
	 goto(WorldObject)).
strategy(goto(Object),
	 ( let(top_level_container(Object, Place),
	       ( call(assert($task/location_bids/Place:Priority)),
		 wait_event(arrived_at(Place)),
		 call(retract($task/location_bids/Place))) ) )) :-
   $task/priority:Priority.