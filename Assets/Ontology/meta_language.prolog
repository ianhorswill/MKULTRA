:- public is_a/2, kind_of/2.
:- public kind/1, leaf_kind/1.
:- public property_value/3, related/3.
:- public process_kind_hierarchy/0.
:- public has_property/2, has_relation/2.
:- public declare_object/3.
:- public kind_lub/3, kind_glb/3.

:- external declare_value/3, default_value/3, declare_related/3.

:- randomizable declare_kind/2.

is_a(Object, Kind) :-
   var(Object),
   var(Kind),
   throw(error("is_a/2 called with neither argument instantiated")).
is_a(Object, Kind) :-
   atomic(Object),
   assertion(valid_kind(Kind), "Invalid kind"),
   is_a_aux(Object, ImmediateKind),
   superkind_array(ImmediateKind, Supers),
   array_member(Kind, Supers).
is_a(Object, Kind) :-
   var(Object),
   assertion(valid_kind(Kind), "Invalid kind"),
   subkind_array(Kind, Subs),
   array_member(Sub, Subs),
   is_a_aux(Object, Sub).

is_a_aux(Object, Kind) :-
   /brainwash/Object/kind ->
      /brainwash/Object/kind/Kind
      ;
      declare_kind(Object, Kind).

valid_kind(Kind) :-
   var(Kind),
   !.
valid_kind(Kind) :-
   atomic(Kind),
   kind(Kind).

kind_of(K, K).
kind_of(Sub, Super) :-
   atomic(Sub),
   superkind_array(Sub, Supers),
   array_member(Super, Supers).
kind_of(Sub, Super) :-
   atomic(Super),
   var(Sub),
   subkind_array(Super, Subs),
   array_member(Sub, Subs).

:- public immediate_superkind_of/2.

immediate_superkind_of(K, Sub) :-
   immediate_kind_of(Sub, K).

superkinds(Kind, Superkinds) :-
   atomic(Kind),
   topological_sort([Kind], immediate_kind_of, Superkinds).

subkinds(Kind, Subkinds) :-
   atomic(Kind),
   topological_sort([Kind], immediate_superkind_of, Subkinds).

superkind_array(Kind, Array) :-
   call_with_step_limit(10000, superkinds(Kind, List)),
   list_to_array(List, Array),
   asserta( ( $global::superkind_array(Kind, Array) :- ! ) ).

subkind_array(Kind, Array) :-
   call_with_step_limit(10000, subkinds(Kind, List)),
   list_to_array(List, Array),
   asserta( ( $global::subkind_array(Kind, Array) :- ! ) ).

% This version handles multiple LUBs, but then it turned out the hierarchy doesn't currently have multiple lubs.
% lub(Kind1, Kind2, LUB) :-
%    atomic(Kind1),
%    atomic(Kind2),
%    superkind_array(Kind1, A1),
%    superkind_array(Kind2, A2),
%    lub_not_including(A1, A2, LUB, []).

% lub_not_including(A1, A2, LUB, AlreadyFound) :-
%    array_member(Candidate, A1),
%    array_member(Candidate, A2),
%    \+ (member(Previous, AlreadyFound), kind_of(Previous, Candidate)),
%    !,
%    (LUB = Candidate ; lub_not_including(A1, A2, LUB, [Candidate | AlreadyFound])).

kind_lub(Kind1, Kind2, LUB) :-
   atomic(Kind1),
   atomic(Kind2),
   superkind_array(Kind1, A1),
   superkind_array(Kind2, A2),
   array_member(LUB, A1),
   array_member(LUB, A2),
   !.

kind_glb(Kind1, Kind2, GLB) :-
   atomic(Kind1),
   atomic(Kind2),
   subkind_array(Kind1, A1),
   subkind_array(Kind2, A2),
   array_member(GLB, A1),
   array_member(GLB, A2),
   !.

%% property_nondefault_value(?Object, ?Property, ?Value)
%  Object has this property value explicitly declared, rather than inferred.
property_nondefault_value(Object, Property, Value) :-
   declare_value(Object, Property, Value).

%% property_value(?Object, ?Property, ?Value)
%  Object has this value for this property.
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

%% related_nondefault(?Object, ?Relation, ?Relatum)
%  Object and Relatum are related by Relation through an explicit declaration.
related_nondefault(Object, Relation, Relatum) :-
   decendant_relation(D, Relation),
   declare_related(Object, D, Relatum).

%% related(?Object, ?Relation, ?Relatum)
%  Object and Relatum are related by Relation.
related(Object, Relation, Relatum) :-
   decendant_relation(D, Relation),
   declare_related(Object, D, Relatum).

decendant_relation(R, R).
decendant_relation(D, R) :-
   implies_relation(I, R),
   decendant_relation(D, I).

ancestor_relation(R,R).
ancestor_relation(A, R) :-
   implies_relation(R, I),
   ancestor_relation(A, I).

declare_object(Object,
	       Properties,
	       Relations) :-
   begin(forall(member((Property=Value), Properties),
		assert(declare_value(Object, Property, Value))),
	 forall(member((Relation:Relatum), Relations),
		assert(declare_related(Object, Relation, Relatum)))).

load_special_csv_row(RowNumber, kinds(Kind, Parents, Singular, Plural)) :-
   define_kind(RowNumber, Kind, Parents),
   define_kind_noun(Kind, Singular, Plural).

define_kind(RowNumber, Kind, _) :-
   kind(Kind),
   throw(error(row:RowNumber:kind_already_defined:Kind)).
define_kind(RowNumber, Kind, [ ]) :-
   Kind \= entity,
   throw(error(row:RowNumber:kind_has_no_parents:Kind)).
define_kind(_, Kind, Parents) :-
   assert(kind(Kind)),
   forall(member(P, Parents),
	  assert(immediate_kind_of(Kind, P))).

define_kind_noun(_, "-", _).  % No noun defined
define_kind_noun(Kind, "", Plural) :-
   atom_string(Kind, Singular),
   define_kind_noun(Kind, Singular, Plural).
define_kind_noun(Kind, Singular, "") :-
   plural_form(Singular, Plural),
   define_kind_noun(Kind, Singular, Plural).
define_kind_noun(Kind, Singular, Plural) :-
   atom_string(SAtom, Singular),
   atom_string(PAtom, Plural),
   assert(kind_noun(Kind, SAtom, PAtom)).

noun(Singular, Plural, X^is_a(X, Kind)) :-
   kind_noun(Kind, Singular, Plural).

end_csv_loading(kinds) :-
   % Find all the leaf kinds
   forall((kind(K), \+ immediate_kind_of(_, K)),
	   assert(leaf_kind(K))).

end_csv_loading(predicate_type) :-
   forall(predicate_type(Type, ArgTypes),
	  check_predicate_signature(Type, ArgTypes)).

check_predicate_signature(Type, ArgTypes) :-
   \+ kind(Type),
   log(bad_declared_type(ArgTypes, Type)).
check_predicate_signature(_Type, ArgTypes) :-
   ArgTypes =.. [_Functor | Types],
   forall(member(AType, Types),
	  ((kind(AType),!) ; log(bad_declared_argument_type(AType, ArgTypes)))).
	  