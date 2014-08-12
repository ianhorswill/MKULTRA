:- public is_a/2, kind_of/2.
:- public kind/1, leaf_kind/1.
:- public property_value/3, related/3.
:- public process_kind_hierarchy/0.
:- public has_property/2, has_relation/2.
:- public declare_object/3.

:- external declare_value/3, default_value/3, declare_related/3.

is_a(Object, Kind) :-
   declare_kind(Object, ImmediateKind),
   kind_of(ImmediateKind, Kind).

kind_of(K, K).
kind_of(Sub, Super) :-
   immediate_kind_of(Sub, K),
   kind_of(K, Super).

property_value(Object, Property, Value) :-
   nonvar(Property),
   !,
   lookup_property_value(Object, Property, Value).
property_value(Object, Property, Value) :-
   is_a(Object, Kind),
   has_property(Kind, Property),
   lookup_property_value(Object, Property, Value).

lookup_property_value(Object, Property, Value) :-
   declare_value(Object, Property, Value), !.
lookup_property_value(Object, Property, Value) :-
   is_a(Object, Kind),
   default_value(Kind, Property, Value), !.

related(Object, Relation, Relatum) :-
   decendant_relation(D, Relation),
   declare_related(Object, D, Relatum).

decendant_relation(R, R).
decendant_relation(D, R) :-
   implies_relation(I, R),
   decendant_relation(D, I).

declare_object(Object,
	       Properties,
	       Relations) :-
   begin(forall(member((Property=Value), Properties),
		assert(declare_value(Object, Property, Value))),
	 forall(member((Relation:Relatum), Relations),
		assert(declare_related(Object, Relation, Relatum)))).

process_kind_hierarchy :-
				% Find all the kinds
   for_all_unique(K,
		  ( immediate_kind_of(K1,K2),
		    ( K=K1 ; K=K2 ) ),
		  assert(kind(K))),
				% Find all the leaf kinds
   forall((kind(K), \+ immediate_kind_of(_, K)),
	   assert(leaf_kind(K))),
				% Warn about any orphan kinds
   forall((kind(K), \+ immediate_kind_of(K, _), K \= entity),
	  log(orphan_kind(K))).
	  