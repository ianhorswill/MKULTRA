known_object(Object) :-
   for_all_unique(Object,
		  declare_kind(Object, _),
		  true).

known_type(number).
known_type(string).
known_type(List) :-
   list(List).
known_type(kind_of(Kind)) :-
   kind(Kind).
known_type(subkind_of(Kind)) :-
   kind(Kind).
known_type(Kind) :-
   kind(Kind).

known_property(Property) :-
   for_all_unique(Property, property_type(Property, _, _)).

known_relation(Relation) :-
   for_all_unique(Relation, relation_type(Relation, _, _)).

test(integrity(property_declarations_well_formed),
     [ true(Malformed == []) ]) :-
   all(Property,
       ( property_type(Property, ObjectType, ValueType),
	 \+ ( known_type(ObjectType),
	      known_type(ValueType) ) ),
       Malformed).

test(integrity(properties_declared),
     [ true(UndeclaredProperties == []) ]) :-
   all(Property,
       ( declare_value(_, Property, _),
	 \+ property_type(Property, _, _) ),
       UndeclaredProperties).

test(integrity(valid_property_types),
     [ true(InvalidValues == []) ]) :-
   all(Object.Property=Value,
       ( declare_value(Object, Property, Value),
	 property_type(Property, ObjectType, ValueType),
	 \+ ( is_type(Object, ObjectType),
	      is_type(Value, ValueType) ) ),
       InvalidValues).

test(integrity(relation_declarations_well_formed),
     [ true(Malformed == []) ]) :-
   all(Relation,
       ( relation_type(Relation, ObjectType, ValueType),
	 \+ ( known_type(ObjectType),
	      known_type(ValueType) ) ),
       Malformed).

test(integrity(relations_declared),
     [ true(UndeclaredRelations == []) ]) :-
   all(Relation,
       ( declare_related(_, Relation, _),
	 \+ relation_type(Relation, _, _) ),
       UndeclaredRelations).

test(integrity(inverse_relations_must_be_declared_in_their_canonical_form),
     [ true(Malformed == []) ]) :-
   all(related(X, R, Y),
       ( declare_related(X, R, Y),
	 inverse_relation(R, _) ),
       Malformed).

test(integrity(valid_relation_types),
     [ true(InvalidValues == []) ]) :-
   all(Object:Relation:Value,
       ( declare_related(Object, Relation, Value),
	 relation_type(Relation, ObjectType, ValueType),
	 \+ ( is_type(Object, ObjectType),
	      is_type(Value, ValueType) ) ),
       InvalidValues).

test(integrity(implied_relations_must_be_defined),
     [ true(UndeclaredRelations == []) ]) :-
   all((R: S),
       ( implies_relation(R, S),
	 \+ ( relation_type(R, _, _),
	      relation_type(S, _, _) )),
       UndeclaredRelations).

test(integrity(implied_relations_must_be_type_consistent),
     [ true(UndeclaredRelations == []) ]) :-
   all((R: S),
       ( implies_relation(R, S),
	 \+ ( relation_type(R, RTO, RTR),
	      relation_type(S, STO, STR),
	      kind_of(RTO, STO),
	      kind_of(RTR, STR) ) ),
       UndeclaredRelations).

test(integrity(intransitive_verb_semantics_defined),
     [ true(UndefinedPredicates = []) ]) :-
   all(Spec:Phrase,
       ( iv(past_participle, _, Semantics, _, _, Phrase, [ ]),
	 lambda_contains_undefined_predicate(Semantics, Spec) ),
       UndefinedPredicates).

test(integrity(transitive_verb_semantics_defined),
     [ true(UndefinedPredicates = []) ]) :-
   all(Spec:Phrase,
       ( tv(past_participle, _, Semantics, _, _, Phrase, [ ]),
	 lambda_contains_undefined_predicate(Semantics, Spec) ),
       UndefinedPredicates).

test(integrity(ditransitive_verb_semantics_defined),
     [ true(UndefinedPredicates = []) ]) :-
   all(Spec:Phrase,
       ( dtv(past_participle, _, Semantics, _, _, Phrase, [ ]),
	 lambda_contains_undefined_predicate(Semantics, Spec) ),
       UndefinedPredicates).

test(integrity(adjective_semantics_defined),
     [ true(UndefinedPredicates = []) ]) :-
   all(Spec:Word,
       ( adjective(Word, Semantics),
	 lambda_contains_undefined_predicate(Semantics, Spec) ),
       UndefinedPredicates).

lambda_contains_undefined_predicate(_^P, Spec) :-
   !,
   lambda_contains_undefined_predicate(P, Spec).
lambda_contains_undefined_predicate(related(_, Relation, _),
				    relation(Relation)) :-
   !,
   \+ relation_type(Relation, _, _).
lambda_contains_undefined_predicate(property_value(_, Property, _),
				    property(Property)) :-
   !,
   \+ property_type(Property, _, _).
lambda_contains_undefined_predicate(P,Name/Arity) :-
   functor(P, Name, Arity),
   functor(Copy, Name, Arity),
   \+ predicate_type(_, Copy).