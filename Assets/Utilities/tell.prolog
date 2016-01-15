%%%
%%% Simple forward-chaining system
%%%

:- op(1200, xfx, '==>').
:- external (==>)/2.


tell(P) :-
   % this should technically be clause(P, true), but that's slower,
   % and the current version of clause doesn't grok the /, :, and :: operators.
   P,
   !.
tell(P) :-
   assert(P),
   forall(when_added(P, Action),
	  begin(Action)).

when_added(P, tell(Q)) :-
   (P ==> Q).
