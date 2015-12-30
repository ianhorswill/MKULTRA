%%%
%%% Simple forward-chaining system
%%%

:- op(1200, xfx, '==>').
:- external (==>)/2.


tell(P) :-
   already_asserted(P),
   !.
tell(P) :-
   assert(P),
   forall(when_added(P, Action),
	  begin(Action)).

% This is slightly complicated because assert/1 and retract/1 know about the EL
% database, but clause/2 doesn't.  Maybe fix this sometime.
already_asserted(Node/Key) :-
   !,
   Node/Key.
already_asserted(Node:Key) :-
   !,
   Node:Key.
already_asserted(P) :-
   clause(P, true).

when_added(P, tell(Q)) :-
   (P ==> Q).
