%%%
%%% Simple forward-chaining system
%%%

:- op(1200, xfx, '==>').
:- external (==>)/2.

tell(P) :-
   clause(P, true),
   !.
tell(P) :-
   assert(P),
   forall(when_added(P, Action),
	  begin(Action)).

when_added(P, tell(Q)) :-
   (P ==> Q).
