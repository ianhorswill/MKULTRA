location(PhysicalObject, Location) :-
   /perception/location/PhysicalObject:Location.

unique_answer(X, location(_Object, X)).

incompatible(location(X, Y),
	     location(X, Z)) :-
   Y \= Z.

in_room(PhysicalObject, Room) :-
   location(PhysicalObject, Room),
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
