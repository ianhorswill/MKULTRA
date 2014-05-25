:- public begin_concern/1, begin_concern/2, begin_child_concern/4,
    kill_concern/1, kill_children/1, goto_state/2.
:- external on_enter_state/2, on_exit_state/2, on_kill/2.

character_initialization :-
    forall(standard_concern(Type),
	   begin_concern(Type)).

begin_concern(Type) :-
    begin_concern(Type, _).

begin_concern(Type, Child) :-
    Parent is $root,
    begin_child_concern(Parent, Type, Child).

begin_child_concern(Parent, Type, Child, Assertions) :-
    begin(allocate_UID(ChildUID),
	  assert(Parent/concerns/ChildUID/type:Type),
	  Parent/concerns/ChildUID>>Child,
	  forall(member(A, Assertions),
		 assert(A)),
	  goto_state(Child, start)).

goto_state(Concern, State) :-
    ignore(( Concern/state:OldState,
	     on_exit_state(Concern, OldState) )),
    Time is $now,
    assert(Concern/state:State/enter_time:Time),
    Concern/type:Type,
    ignore(on_enter_state(Type, Concern, State)).

begin_child_concern(Parent, Type, Child) :-
    begin_child_concern(Parent, Type, Child, [ ]).

kill_concern(Concern) :-
    begin(Concern/type:Type,
	  ignore(on_kill(Type, Concern)),
	  kill_children(Concern),
	  retract(Concern)).

kill_children(Concern) :-
    forall(Concern/concerns/_>>Subconcern,
	   kill_concern(Subconcern)).

allocate_UID(ChildUID) :-
    begin(/next_uid:ChildUID,
	  NextUID is ChildUID+1,
	  assert(/next_uid:NextUID)).

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
