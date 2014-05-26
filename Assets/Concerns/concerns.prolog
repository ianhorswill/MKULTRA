%%%
%%% CONCERN SYSTEM
%%%

%%
%% Enumeration
%%

%% concern(?Concern, ?Type)
%  Concern is an existing concern of type Type.
concern(Concern, Type) :-
    concern(Concern),
    Concern/type:Type.

%% concern(?Concern)
%  Concern is an existing concern.
concern(A) :-
       R is $root,
       descendant_concern_of(R, A).

%% descendant_concern_of(?Ancestor, ?Descendant)
%  Both Ancestor and Descendant are existing concerns and Descendent
%  is a descendent of Ancestor in the tree.
descendant_concern_of(Ancestor, Descendant) :-
    Ancestor/concerns/_>>Child,
    ( Descendant=Child 
      ; descendant_concern_of(Child,Descendant) ).

%%
%% Creation
%%

:- public begin_concern/1, begin_concern/2, begin_child_concern/3.

%% begin_concern(+Type)
%  IMPERATIVE
%  Creates a new concern of type Type at top level.
begin_concern(Type) :-
    begin_concern(Type, _).

%% begin_concern(+Type, -Child)
%  IMPERATIVE
%  Creates a new concern of type Type at top level and returns its ELNode in Child.
begin_concern(Type, Child) :-
    Parent is $root,
    begin_child_concern(Parent, Type, Child).

%% begin_child_concern(+Parent, +Type, -Child, +Assertions)
%  IMPERATIVE
%  Creates a new concern of type Type as a child of Parent, and returns its ELNode in Child.
%  Adds Assertions to its ELNode.
begin_child_concern(Parent, Type, Child, Assertions) :-
    begin(allocate_UID(ChildUID),
	  assert(Parent/concerns/ChildUID/type:Type),
	  Parent/concerns/ChildUID>>Child,
	  forall(member(A, Assertions),
		 assert(A)),
	  goto_state(Child, start)).

%% begin_child_concern(+Parent, +Type, -Child)
%  IMPERATIVE
%  Creates a new concern of type Type as a child of Parent, and returns its ELNode in Child.
begin_child_concern(Parent, Type, Child) :-
    begin_child_concern(Parent, Type, Child, [ ]).

%%
%% Destruction
%%

:- public kill_concern/1.

%% kill_concern(+Concern)
%  Kills concern and all its children.
%  Calls on_kill/2 on it before deletion.
kill_concern(Concern) :-
    begin(Concern/type:Type,
	  ignore(on_kill(Type, Concern)),
	  kill_children(Concern),
	  retract(Concern)).

%% kill_children(+Concern)
%  Calls kill_concern/1 on all children of Concern.

:- public kill_children/1.

kill_children(Concern) :-
    forall(Concern/concerns/_>>Subconcern,
	   kill_concern(Subconcern)).

%% on_kill(+Type, +Concern)
%  IMPERATIVE
%  Called when Concern is to be destroyed.
%  Called before either it or its children are destroyed.

:- external on_kill/2.

%%
%% State switching
%%

%% goto_state(+Concern, +State)
%  Switches Concern to State, running entry/exit handlers as appropriate.

:- public goto_state/2.

goto_state(Concern, State) :-
    Concern/type:Type,
    ignore(( Concern/state:OldState,
	     on_exit_state(OldState, Type, Concern) )),
    Time is $now,
    assert(Concern/state:State/enter_time:Time),
    ignore(on_enter_state(State, Type, Concern)).

%% on_enter_state(+NewState, +Type, +Concern)
%  IMPERATIVE
%  Called just after Concern is switched to state NewState.

:- external on_enter_state/3.

%% on_exit_state(+OldState, +Type, +Concern)
%  IMPERATIVE
%  Called just before Concern is switched from state OldState.

:- external on_exit_state/3.

%%
%% Initialization
%%

character_initialization :-
    forall(standard_concern(Type),
	   begin_concern(Type)).

%% standard_concern(+Type)
%  Type is a standard concern.
%  It will be spawn automatically upon character initialization.

:- external standard_concern/1.
