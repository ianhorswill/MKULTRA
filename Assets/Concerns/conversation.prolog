my_turn(C) :-
    /perception/nobody_speaking,
    C/last_dialog:dialog(_, $this, _).

propose_action(conversation, C, ack(greeting)) :-
    C/state:start, my_turn(C).

on_event(conversation, C, dialog($this, _, ack(greeting))) :-
    goto_state(C, normal).

on_event(conversation, C, exit_social_space(Character)) :-
    C/interlocutor/Character,
    kill_concern(C).
