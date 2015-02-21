:- public assertion/2, thaw/1, arguments_unbound/2.
:- higher_order(assertion(1,0)).

%% arguments_unbound(+Structure, -Unbound)
%  Unbound is a structure with the same functor and arity as Structure,
%  but with all its arguments replaced with fresh variables.
arguments_unbound(In, Out) :-
   functor(In, Name, Arity),
   functor(Out, Name, Arity).

%% term_append(+Structure, +List, -ExtendedStructure) is det
%  ExtendedStructure is Structure with the extra arguments List appended.
term_append(Term, AdditionalArgs, ExtendedTerm) :-
   Term =.. List,
   append(List, AdditionalArgs, ExtendedList),
   ExtendedTerm =.. ExtendedList.

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