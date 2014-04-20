/next_uid:0.

spawn_activity(Type, Child) :-
    Parent is $root,
    spawn_activity(Parent, Type, Child).

spawn_activity(Parent, Type, Child) :-
    allocate_UID(ChildUID),
    assert(Parent/activities/ChildUID/type:Type),
    Parent/activities/ChildUID>>Child,
    ignore(on_initiate(Type, Child)).

kill_activity(Activity) :-
    Activity/type:Type,
    ignore(on_kill(Type, Activity)),
    retract(Activity).

allocate_UID(ChildUID) :-
    /next_uid:ChildUID,
    NextUID is ChildUID+1,
    assert(/next_uid:NextUID).

kill_all_activities :-
    forall(/activities/_>>Activity, 
	   kill_activity(Activity)).

%on_initiate(_,_).
%on_kill(_,_).
