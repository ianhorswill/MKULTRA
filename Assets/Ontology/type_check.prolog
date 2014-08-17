well_typed(Object, Kind, Bindings) :-
   well_typed(Object, Kind, [ ], Bindings).

well_typed(Var, Kind, BIn, BOut) :-
   var(Var),
   !,
   variable_well_typed(Var, Kind, BIn, BOut).

well_typed(Atom, Kind, Bindings, Bindings) :-
   atomic(Atom),
   !,
   is_a(Atom, Kind).

well_typed((Expression, is_a(Var, VKind)), Kind, BIn, BOut) :-
   well_typed(Expression, Kind, [Var:VKind | BIn], BOut).

well_typed(Event, Kind, BindingsIn, BindingsOut) :-
   Event =.. [Functor | ActualArgs],
   copy_list_as_variables(ActualArgs, ArgTypes),
   TypeDecl =.. [Functor | ArgTypes],
   type(TypeDecl, Kind),
   well_typed_arguments(ActualArgs, ArgTypes, BindingsIn, BindingsOut).

well_typed_arguments([], [], Bindings, Bindings).
well_typed_arguments([Arg | Args], [Type | Types], BIn, BOut) :-
   well_typed(Arg, Type, BIn, BIntermediate),
   well_typed_arguments(Args, Types, BIntermediate, BOut).

copy_list_as_variables([], []).
copy_list_as_variables([_ | T1], [_ | T2]) :-
   copy_list_as_variables(T1, T2).

variable_well_typed(V, Kind, BIn, BOut) :-
   lookup_variable_type(V, PreviousKind, BIn),
   !,
   variable_well_typed(V, Kind, PreviousKind, BIn, BOut).
variable_well_typed(V, Kind, B, [V:Kind | B]).  % haven't seen this var before.

variable_well_typed(_V, Kind, PreviousKind, B, B) :-
   kind_of(PreviousKind, Kind),  % We already have a type that's at least as specific.
   !.
variable_well_typed(V, Kind, PreviousKind, B, [V:Kind | B]) :-
   kind_of(Kind, PreviousKind),  % Kind is a more specific type. 
   !.

lookup_variable_type(Var, Type, [V:T | Tail]) :-
   (Var == V) -> Type=T ; lookup_variable_type(Var, Type, Tail).

type(eat(person, food), action).
type(move(person, physical_object, container), action).
type(can(action), condition).
type(location(physical_object, container), condition).
