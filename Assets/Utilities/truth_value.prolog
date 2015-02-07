:- public truth_value/2, admitted_truth_value/3, know_that/1.
:- external know_whether/1, pretend_truth_value/3.
:- external know_property/3, know_relation/3,
            know_about_kind/1.

truth_value(P, unknown) :-
   \+ know_whether(P),
   !.
truth_value(P, true) :-
   P.
truth_value(P, false) :-
   \+ P.

know_that(P) :-
   know_whether(P),
   P.

know_whether(is_a(Object, _Kind)) :-
   !,
   know_about_object(Object).

know_whether(property_value(Object, Property, Value)) :-
   !,
   know_property(Property, Object, Value).

know_whether(related(Object, Relation, Relatum)) :-
   !,
   know_relation(Relation, Object, Relatum).

know_whether(_).

know_relation(_, $me, _).
know_property(_, $me, _).

know_about_object(Object) :-
   atomic(Object),
   is_a(Object, Kind),
   know_about_kind(Kind).

:- external pretend_truth_value/3.

admitted_truth_value(Listener, P, Value) :-
   Listener \= $me,
   pretend_truth_value(Listener, P, _),
   !,
   pretend_truth_value(Listener, P, Value),
   emit_grain("lie", 100).
admitted_truth_value(_, P, Value) :-
   truth_value(P, Value).
