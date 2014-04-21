propose_action(be_polite, Activity, say("Sorry!")) :-
    Activity/bumped,
    retract(Activity/bumped).

score_action(be_polite, _, say("Sorry!"), 100).

on_event(be_polite, Activity, collision(X)) :-
    character(X),
    assert(Activity/bumped).

:- spawn_activity(be_polite, _).
