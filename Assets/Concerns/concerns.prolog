begin_concern(Type) :-
    begin_concern(Type, _).

begin_concern(Type, Child) :-
    Parent is $root,
    begin_child_concern(Parent, Type, Child).

begin_child_concern(Parent, Type, Child) :-
    allocate_UID(ChildUID),
    assert(Parent/concerns/ChildUID/type:Type),
    Parent/concerns/ChildUID>>Child,
    ignore(on_initiate(Type, Child)).

kill_concern(Concern) :-
    Concern/type:Type,
    ignore(on_kill(Type, Concern)),
    kill_children(Concern),
    retract(Concern).

kill_children(Concern) :-
    forall(Concern/concerns/_>>Subconcern,
	   kill_concern(Subconcern)).

allocate_UID(ChildUID) :-
    /next_uid:ChildUID,
    NextUID is ChildUID+1,
    assert(/next_uid:NextUID).

kill_all_concerns :-
    Root is $root,
    kill_children(Root).

concern(Concern, Type) :-
    concern(Concern),
    Concern/type:Type.

concern(A) :-
       R is $root,
       descendant_concern_of(R, A).
descendant_concern_of(Ancestor, Descendant) :-
    Ancestor/concerns/_>>Child,
    ( Descendant=Child 
      ; descendant_concern_of(Child,Descendant) ).
