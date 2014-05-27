on_enter_state(start,
	       conversation, C) :-
    C/partner/You,
    assert(C/location_bids/You:200).

%% my_turn(C) :-
%%     /perception/nobody_speaking,
%%     C/last_dialog:dialog(_, $this, _).

%% OPENINGS

propose_action(greet($me, You), 
	       conversation, C) :-
    \+ C/said_greeting,
    C/partner/You.

score_action(greet($me, _You),
	     conversation, _,
	     100).

on_event(greet($me, You),
	 conversation, C,
	 assert(C/said_greeting)) :-
    C/partner/You.

on_event(greeting(You, $me),
	 conversation, C,
	 assert(C/heard_greeting)) :-
    C/partner/You.

% CLOSINGS

on_event(parting($me, You),
	 conversation, C,
	 (assert(C/said_parting), maybe_end_conversation(C))) :-
    C/partner/You.

on_event(parting(You, $me),
	 conversation, C,
	 (assert(C/heard_parting), maybe_end_conversation(C))) :-
    C/partner/You.

maybe_end_conversation(C) :-
    C/said_parting,
    C/heard_parting,
    kill_concern(C).
maybe_end_conversation(_).

propose_action(parting($me, You),
	       conversation, C) :-
    want_to_end_conversation(C),
    \+ C/said_parting,
    C/partner/You.

score_action(parting($me,You),
	     conversation, C,
	     100) :-
    C/partner/You.

want_to_end_conversation(C) :-
    C/heard_parting.
want_to_end_conversation(C) :-
    C/state:start/enter_time:Time,
    Time+4 < $now.

% ABRUPT CLOSINGS

on_event(exit_social_space(Character),
	 conversation, C,
	 kill_concern(C)) :-
    C/partner/Character.

