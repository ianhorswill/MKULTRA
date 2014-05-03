score_action(be_polite, _, dialog($this, _, apology), 100).
score_action(be_polite, _, dialog($this, _, greeting), 50).

on_event(be_polite, _, collision(X)) :-
    character(X),
    propose_once(dialog($this, X, apology)).

on_event(be_polite, _, enter_social_space(Character)) :-
    propose_once(dialog($this, Character, greeting)).
