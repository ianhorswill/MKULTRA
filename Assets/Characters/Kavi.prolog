/goals/maintain/bedroom_empty.
/perception/location/ $macguffin : $bookshelf.
/parameters/poll_time:3.

pretend_truth_value(Asker,
		    location($macguffin, Loc),
		    T) :-
   \+ related(Asker, member_of, illuminati),
   (var(Loc) -> T = unknown ; T = false).
pretend_truth_value(Asker,
		    contained_in($macguffin, Loc),
		    T) :-
   \+ related(Asker, member_of, illuminati),
   (var(Loc) -> T = unknown ; T = false).
   
:- public bedroom_empty/0.
bedroom_empty :-
   \+ intruder(_Intruder, $bedroom).

intruder(Intruder, Room) :-
   location(Intruder, Room),
   is_a(Intruder, person),
   \+ related(Intruder, member_of, illuminati).

personal_strategy(achieve(bedroom_empty),
		  ( ingest(Intruder),
		    discourse_increment($me, Intruder,
					["Stay out of my bedroom!"]) )) :-
   intruder(Intruder, $bedroom).
