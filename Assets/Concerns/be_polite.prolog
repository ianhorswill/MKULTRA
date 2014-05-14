standard_concern(be_polite).

score_action(be_polite, _, dialog(_, _, apology), 100).
score_action(be_polite, _, dialog(_, _, greeting), 50).

on_event(be_polite, _, collision(X),
	 propose_once(dialog(Me, X, apology))) :-
    character(X),
    Me is $game_object.

on_event(be_polite, _, enter_social_space(Character),
	 propose_once(dialog(Me, Character, greeting))) :-
    Me is $game_object.
    
