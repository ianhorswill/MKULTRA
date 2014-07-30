has_property(physical_object, location).
has_relation(physical_object, commonly_found_at).

location(PhysicalObject, Location) :-
   /perception/location/PhysicalObject:Location.

in_room(PhysicalObject, Room) :-
   location(PhysicalObject, Room),
   room(Room).

top_level_container(PhysicalObject, Container) :-
   location(PhysicalObject, C),
   (room(C) ->
       Container=PhysicalObject
       ;
       top_level_container(C, Container) ).


