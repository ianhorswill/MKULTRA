my_turn(C) :-
    /perception/nobody_speaking,
    C/last_dialog:dialog(_, $this, _).

propose_action(conversation, C, ack(greeting)) :-
    C/state:start, my_turn.

on_event(conversation, C, dialog($this, _, ack(greeting))) :-
    goto_state(C, normal).
