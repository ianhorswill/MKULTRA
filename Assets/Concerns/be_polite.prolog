standard_concern(be_polite).

score_action(be_polite, _, dialog(_, _, apology), 100).
score_action(be_polite, _, dialog(_, _, greeting), 50).

on_event(be_polite, _, collision(X)) :-
    character(X),
    Me is $game_object,
    propose_once(dialog(Me, X, apology)).

on_event(be_polite, _, enter_social_space(Character)) :-
    Me is $game_object,
    propose_once(dialog(Me, Character, greeting)).
