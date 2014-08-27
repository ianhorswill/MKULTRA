:- public assertion/2.
:- higher_order(assertion(1,0)).

assertion(P, _) :-
   P,
   !.
assertion(P, Message) :-
   throw(error(assertion_failed(Message, P), null)).
