propose_action(be_polite, Activity, say("Sorry!")) :-
    Activity/bumped,
    retract(Activity/bumped).

propose_action(be_polite, Activity, say("Hey")) :-
    Activity/new_arrival,
    retract(Activity/new_arrival).

score_action(be_polite, _, say("Sorry!"), 100).
score_action(be_polite, _, say("Hey"), 50).

on_event(be_polite, Activity, collision(X)) :-
    character(X),
    assert(Activity/bumped).

on_event(be_polite, Activity, enter_conversational_space(X)) :-
    assert(Activity/new_arrival:X).

:- spawn_activity(be_polite, _).
