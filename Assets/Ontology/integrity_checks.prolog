known_object(Object) :-
   for_all_unique(Object,
		  declare_kind(Object, _),
		  true).

known_type(number).
known_type(string).
known_type(List) :-
   list(List).
known_type(kind_of(Kind)) :-
   known_kind(Kind).
known_type(Kind) :-
   known_kind(Kind).
known_kind(Kind) :-
   kind_of(Kind, entity).

known_property(Property) :-
   for_all_unique(Property, property_type(Property, _, _)).

known_relation(Relation) :-
   for_all_unique(Relation, relation_type(Relation, _, _)).

is_type(Object, number) :-
   number(Object), !.
is_type(Object, string) :-
   string(Object), !.
is_type(Object, kind) :-
   known_kind(Object).
is_type(Object, List) :-
   list(List),
   member(Object, List).
is_type(Object, kind_of(Kind)) :-
   kind_of(Object, Kind).
is_type(Object, Kind) :-
   is_a(Object, Kind).

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
