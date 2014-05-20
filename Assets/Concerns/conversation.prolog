on_enter_state(conversation, C, start) :-
    C/interlocutor/You,
    assert(C/location_bids/You:200).

my_turn(C) :-
    /perception/nobody_speaking,
    C/last_dialog:dialog(_, $this, _).

%% OPENINGS AND CLOSINGS

on_event(conversation, C, exit_social_space(Character),
	 kill_concern(C)) :-
    C/interlocutor/Character.

on_event(conversation, C, begin(dialog(Me, You, Act)),
	 Handler) :-
    C/interlocutor/You,
    conversational_move(C, dialog(Me, You, Act), Handler).

on_event(conversation, C, dialog(X,Y, Act),
	 Handler) :-
    C/interlocutor/X,
    Y is $this,
    conversational_move(C, dialog(X,Y, Act), Handler).

conversational_move(C, dialog(X, Y, Act),
		    ignore(handle_transition(C, Act))) :-
    assert(C/last_dialog:dialog(X, Y, Act)).

handle_transition(C, Act) :-
    C/state:CurrentState,
    dialog_transition(CurrentState, Act, NewState, _),
    goto_state(C, NewState).

dialog_transition(start, ack(greeting), normal, 100).
dialog_transition(start, greeting, normal, 0).
dialog_transition(normal, parting, closing, 100).
%dialog_transition(closing, ack(parting), end, 100).
%dialog_transition(closing, parting, end, 0).

%% CONVERSATION BODY

propose_action(conversation, C, stop) :-
    /motor_state/walking_to,
    C/state:normal.

score_action(conversation, _, stop, 200).
