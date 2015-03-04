location(X, Location) :-
   X == player,
   !,
   location($me, Location).
location(Room, Building) :-
   is_a(Room, room),
   property_value(Room, building, Building).
location(Building, the_world) :-
   is_a(Building, building).
location(the_world, the_game).
location(PhysicalObject, Location) :-
   /perception/location/PhysicalObject:Location.

unique_answer(X, location(Object, X)) :-
   var(X),
   nonvar(Object).

incompatible(location(X, Y),
	     location(X, Z)) :-
   Y \= Z.

in_room(PhysicalObject, Room) :-
   location(PhysicalObject, Room),
   room(Room).

top_level_container(Room, Room) :-
   room(Room).
top_level_container(PhysicalObject, Container) :-
   location(PhysicalObject, C),
   (room(C) ->
       Container=PhysicalObject
       ;
       top_level_container(C, Container) ).

contained_in(PhysicalObject, Location) :-
   location(PhysicalObject, Location),
   !.
contained_in(PhysicalObject, Location) :-
   location(PhysicalObject, Container),
   contained_in(Container, Location).

%% room(?X) is nondet
%  X is a room.
room(X) :-
   is_a(X, room).
