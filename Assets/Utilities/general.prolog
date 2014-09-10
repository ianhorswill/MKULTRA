:- public assertion/2, thaw/1.
:- higher_order(assertion(1,0)).

%% assertion(:P. +Message)
%  Throw exception if P is unprovable.
assertion(P, _) :-
   P,
   !.
assertion(P, Message) :-
   throw(error(assertion_failed(Message, P), null)).

%% thaw(?X)
%  If X is an unbound variable with a frozen goal, wakes the goal.
thaw(X) :-
   frozen(X, G),
   G.

test_file(freeze(_), "Utilities/freeze_tests").