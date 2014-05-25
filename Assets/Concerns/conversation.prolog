on_enter_state(conversation, C, start) :-
    C/partner/You,
    assert(C/location_bids/You:200).

%% my_turn(C) :-
%%     /perception/nobody_speaking,
%%     C/last_dialog:dialog(_, $this, _).

%% OPENINGS

propose_action(conversation, C, dialog(Me, You, greeting)) :-
    \+ C/said_greeting,
    C/partner/You,
    Me is $game_object.

score_action(conversation, _, dialog(_, _, greeting), 100).

on_event(conversation, C, begin(dialog(_, You, greeting)),
	 assert(C/said_greeting)) :-
    C/partner/You.

on_event(conversation, C, dialog(You, Me, greeting),
	 assert(C/heard_greeting)) :-
    C/partner/You,
    Me is $game_object.

% CLOSINGS

on_event(conversation, C, begin(dialog(_, You, parting)),
	 (assert(C/said_parting), maybe_end_conversation(C))) :-
    C/partner/You.

on_event(conversation, C, dialog(You, Me, parting),
	 (assert(C/heard_parting), maybe_end_conversation(C))) :-
    C/partner/You,
    Me is $game_object.

maybe_end_conversation(C) :-
    C/said_parting,
    C/heard_parting,
    kill_concern(C).
maybe_end_conversation(_).

propose_action(conversation, C, dialog(Me, You, parting)) :-
    want_to_end_conversation(C),
    \+ C/said_parting,
    Me is $game_object,
    C/partner/You.

score_action(conversation, _, dialog(_, _, parting), 100).

want_to_end_conversation(C) :-
    C/heard_parting.
want_to_end_conversation(C) :-
    C/state:start/enter_time:Time,
    Time+4 < $now.

% ABRUPT CLOSINGS

on_event(conversation, C, exit_social_space(Character),
	 kill_concern(C)) :-
    C/partner/Character.

