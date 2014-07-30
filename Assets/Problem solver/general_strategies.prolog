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

strategy(move(X,Y),
	 putdown(X,Y)).

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