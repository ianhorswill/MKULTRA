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

:- public when/2, when/3, when/4, when/5, when/6.

%% when(?Condition, :Imperatives, ...)
%  Run Imperatives in order if Condition is true, else do nothing
when(P, Imperative) :-
   P -> begin(Imperative) ; true.
when(P, Imperative1, Imperative2) :-
   P -> begin(Imperative1, Imperative2) ; true.
when(P, Imperative1, Imperative2, Imperative3) :-
   P -> begin(Imperative1, Imperative2, Imperative3) ; true.
when(P, Imperative1, Imperative2, Imperative3, Imperative4) :-
   P -> begin(Imperative1, Imperative2, Imperative3, Imperative4) ; true.
when(P, Imperative1, Imperative2, Imperative3, Imperative4, Imperative5) :-
   P -> begin(Imperative1, Imperative2, Imperative3, Imperative4, Imperative5) ; true.

:- public unless/2, unless/3, unless/4, unless/5, unless/6.

%% unless(?Condition, :Imperatives, ...)
%  Run Imperatives in order unless Condition is true.
unless(P, Imperative) :-
   P -> true ; begin(Imperative).
unless(P, Imperative1, Imperative2) :-
   P -> true ; begin(Imperative1, Imperative2).
unless(P, Imperative1, Imperative2, Imperative3) :-
   P -> true ; begin(Imperative1, Imperative2, Imperative3).
unless(P, Imperative1, Imperative2, Imperative3, Imperative4) :-
   P -> true ; begin(Imperative1, Imperative2, Imperative3, Imperative4).
unless(P, Imperative1, Imperative2, Imperative3, Imperative4, Imperative5) :-
   P -> true ; begin(Imperative1, Imperative2, Imperative3, Imperative4, Imperative5).

%%
%% Lambda expressions
%%
reduce(Lambda, Arg, Result) :-
   copy_term(Lambda, Copy),
   reduce_aliasing(Copy, Arg, Result).

reduce_aliasing(Arg^Result, Arg, Result).