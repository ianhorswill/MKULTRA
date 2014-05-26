%%
%% The Patrol activity
%%

rebid_patrol(Concern) :-
    forall(Concern/visited/Prop:Time,
	   begin(Score is ($now-Time)-distance(Prop, $game_object),
		 assert(Concern/location_bids/Prop:Score))).

on_event(arrived_at(Place),
	 patrol, Concern,
	 begin(assert(Concern/visited/Place:Time),
	       rebid_patrol(Concern))) :-
    Time is $now.

on_enter_state(start, patrol, Concern) :-
    forall(prop(P), assert(Concern/visited/P:(-100))),
    rebid_patrol(Concern).
