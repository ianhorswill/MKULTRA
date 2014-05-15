%%
%% The Patrol activity
%%

rebid_patrol(Concern) :-
    forall(Concern/visited/Location,
	   ( Concern/visited/Prop:Time,
	     Score is ($now-Time)-distance(Prop, $game_object),
	     assert(Concern/location_bids/Location:Score) )).

on_event(patrol, Concern,
	 arrived_at(Place),
	 ( assert(Concern/visited/Place:Time),
	   rebid_patrol(Concern) )) :-
    Time is $now.

on_enter_state(patrol, Concern, start) :-
    forall(prop(P), assert(Concern/visited/P:(-100))),
    rebid_patrol(Concern).
