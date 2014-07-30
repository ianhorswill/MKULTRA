%%%
%%% Finding and testing Unity GameObjects
%%%

:- public prop/1, character/1, world_object/1, nearest/2, docked_with/1, after_time/1.

:- public register_room/2, register_prop/4, register_character/3.

register_room(Room, Name) :-
   ensure(room(Room)),
   ensure(declare_kind(Room, room)),
   ensure(proper_noun(Room, Name)).

register_prop(Prop, CommonNoun, Plural, Adjectives) :-
   Predication =.. [CommonNoun, X],
   ensure(noun(CommonNoun, Plural, X^Predication)),
   ensure(prop(Prop)),
   ensure([CommonNoun, Prop]),
   ensure(declare_kind(Prop, CommonNoun)),
   forall(member(A, Adjectives), ensure([A, Prop])).

register_character(Character, Name, Type) :-
   ensure(character(Character)),
   ensure(declare_kind(Character, Type)),
   ensure(proper_noun(Name, Character)).

ensure([Functor | Arguments]) :-
   !,
   Predication =.. [Functor | Arguments],
   ensure(Predication).
ensure(Assertion) :-
   functor(Assertion, F, A),
   external(F/A),
   Assertion ; assertz(Assertion).

%% world_object(?GameObject)
%  GameObject is a prop or character.
world_object(WorldObject) :-
    prop(WorldObject) ; character(WorldObject).

%% nearest(-GameObject, :Constraint)
%  GameObject is the nearest object satisfying Constraint.
nearest(GameObject, Constraint) :-
    arg_min(GameObject,
	    Distance,
	    (Constraint, Distance is distance(GameObject, $me))).

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

