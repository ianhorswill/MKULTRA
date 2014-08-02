initialize_prop(S, work_surface) :-
   component_of_gameobject_with_type(C, S, $'PhysicalObject'),
   set_property(C, "ContentsVisible", true).

initialize_prop(S, container) :-
   component_of_gameobject_with_type(C, S, $'PhysicalObject'),
   set_property(C, "IsContainer", true).