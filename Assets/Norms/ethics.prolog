immoral(Action) :-
   murder(Action).

murder(Action) :-
   patient(Action, Person),
   is_a(Person, person),
   alive(Person),
   true_after(Action, dead(Person)).

				% Don't steal
~permissible(move(Actor, Object, Actor)) :=
   possession(Object, Owner),
   Owner \= Actor.

incompatible(possession(X, O1),
	     possession(X,O2)) :-
   O1 \= O2.

possession(X, Character) :=
   character(Character),
   location(X, Character).