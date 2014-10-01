/goals/maintain/bedroom_empty.
/perception/location/ $macguffin : $bookshelf.
/parameters/poll_time:3.

:- public cover_story/2.
cover_story(_,
	    location($macguffin, _),
	    no).
cover_story(_,
	    contained_in($macguffin, _),
	    no).

:- public bedroom_empty/0.
bedroom_empty :-
   \+ intruder(_Intruder, $bedroom).

intruder(Intruder, Room) :-
   location(Intruder, Room),
   is_a(Intruder, person),
   Intruder \= $me.

personal_strategy(achieve(bedroom_empty),
		  ( ingest(Intruder),
		    discourse_increment($me, Intruder,
					["I told you to stay out of my bedroom!"]) )) :-
   intruder(Intruder, $bedroom).
