%%
%% The Patrol activity
%%

propose_action(patrol, _, goto(Prop)) :-
    not(/motor_state/walking_to),  % not already going somewhere
    /last_destination:Last,
    prop(Prop),
    Prop \= Last.

score_action(patrol, Concern, goto(Prop), Score) :-
    Concern/visited/Prop:Time,
    Score is ($now-Time)-distance(Prop, $game_object).

on_event(patrol, Concern, arrived_at(Place)) :-
    Time is $now,
    assert(Concern/visited/Place:Time).

on_initiate(patrol, Concern) :-
    forall(prop(P), assert(Concern/visited/P:0)).
