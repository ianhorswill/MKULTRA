%%%
%%% Finding and testing Unity GameObjects
%%%

:- public prop/1, character/1, world_object/1, nearest/2, docked_with/1, after_time/1.

:- public register_room/3, register_prop/3, register_character/3.

%% register_room(*Room, *CommonNoun, *Plural)
%  Add Room to the database, ensuring its singular and plural nouns are registered in the lexicon
register_room(Room, CommonNoun, Plural) :-
   ensure(room(Room)),
   ensure(declare_kind(Room, CommonNoun)),
   ( noun(_,_,X^is_a(X, CommonNoun))
     ;
     assertz(noun(CommonNoun, Plural, X^is_a(X,CommonNoun))) ).

%% register_prop(*Prop, *CommonNoun, *Plural, Adjectives)
%  Add Prop to the database, ensuring its singular and plural nouns are registered in the lexicon
register_prop(Prop, Kind, Adjectives) :-
   assertion(kind(Kind), prop_has_unknown_kind(Prop, Kind)),
   ensure(prop(Prop)),
   ensure(declare_kind(Prop, Kind)),
   forall(member(A, Adjectives), ensure([A, Prop])),
   forall(is_a(Prop, K),
	  ignore(initialize_prop(Prop, K))).

%% register_character(*Character, *Name, *Kind)
%  Add Character to database with the specified Name and Kind (male or female).
register_character(Character, Name, Type) :-
   ensure(character(Character)),
   ensure(declare_kind(Character, Type)),
   assert_proper_name(Character, [Name], singular).

%% ensure(+Fact)
%  Adds Fact to database, if it is not already there.
ensure([Functor | Arguments]) :-
   !,
   Predication =.. [Functor | Arguments],
   ensure(Predication).
ensure(Assertion) :-
   functor(Assertion, F, A),
   external(F/A),
   (Assertion ; assertz(Assertion)).

%% world_object(?GameObject)
%  GameObject is a prop or character.
world_object(WorldObject) :-
    prop(WorldObject) ; character(WorldObject).

%% nearest(-GameObject, :Constraint)
%  GameObject is the nearest object satisfying Constraint.
nearest(GameObject, Constraint) :-
    arg_min(GameObject,
	    Distance,
	    ( Constraint,
	      exists(GameObject),
	      Distance is distance(GameObject, $me))).

%% elroot(+GameObject, -Root)
%  Returns the root of the EL database for GameObject, if there is one.

elroot(GameObject, Root) :-
   component_of_gameobject_with_type(KB, GameObject, $'KB'),
   Root is KB.'KnowledgeBase'.'ELRoot' .

%% exists(*GameObject)
%  The specified game object has not been destroyed
exists(X) :-
   is_class(X, $'GameObject'),
   component_of_gameobject_with_type(C, X, $'PhysicalObject'),
   C.'Exists'.
~exists(X) :-
   is_class(X, $'GameObject'),
   component_of_gameobject_with_type(C, X, $'PhysicalObject'),
   \+ C.'Exists'.

%% existing(*Kind, ?GameObject)
%  GameObject is an undestroyed instance of Kind

:- public existing/2.

existing(Kind, Object) :-
   is_a(Object, Kind),
   exists(Object).

:- public dead/1, alive/1.

%% dead(?X)
%  X is a dead (nonexisting) person.
dead(X) :- is_a(X, person), ~exists(X).
~dead(X) :- is_a(X, person), exists(X).

%% alive(?X)
%  X is a living (undestroyed) person
alive(X) :- is_a(X, person), exists(X).
~alive(X) :- is_a(X, person), ~exists(X).

%% docked_with(?GameObject)
%  The character is currently docked with GameObject or its top-level container.
docked_with(WorldObject) :-
   /perception/docked_with:WorldObject.
docked_with(WorldObject) :-
   top_level_container(WorldObject, Container),
   WorldObject \= Container,
   docked_with(Container).

%% after_time(+Time)
%  The current time is after Time.
after_time(Time) :-
   $now > Time.

%%%
%%% Hidden objects
%%%

hidden(X) :-
   component_of_gameobject_with_type(PhysicalObject, X, $'PhysicalObject'),
   PhysicalObject.'IsHidden'.

reveal(X) :-
   component_of_gameobject_with_type(PhysicalObject, X, $'PhysicalObject'),
   PhysicalObject.'SetHidden'(false).

hidden_contents(Container, HiddenObject) :-
   parent_of_gameobject(HiddenObject, Container),
   hidden(HiddenObject).



%%%
%%% Character initialization.
%%%

:- public do_all_character_initializations/0.

%% do_all_character_initializations
%  IMPERATIVE
%  Called once by SimController.Start().
%  DO NOT CALL!
do_all_character_initializations :-
    (character_initialization, fail) ; true.

%% character_initialization
%  All rules for this will be called once when the game object receives a Start() message.
:- external character_initialization/0.

%%%
%%% UID generation
%%%

%% allocate_UID(UID)
%  UID is a unique integer not previously allocated within this character.
allocate_UID(UID) :-
    begin(/next_uid:UID,
	  NextUID is UID+1,
	  assert(/next_uid:NextUID)).

