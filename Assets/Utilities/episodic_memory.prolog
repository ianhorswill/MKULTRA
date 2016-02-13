:- dynamic past_event/1.
:- external memorable_event/1.

maybe_remember_event(Event) :-
   memorable_event(Event),
   asserta(past_event(Event)),
   !.

character_remembers(Character, Event) :-
   character(Character),
   Character::past_event(Event).
