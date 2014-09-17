%%%
%%% Driver for conversation between player and player character
%%%

on_event(player_input(X),
	 player_interaction,
	 C,
	 player_input_task(C, respond_to_dialog_act(X))).

player_input_task(Concern, Input) :-
   kill_children(Concern),
   start_task(Concern, Input, 100, T, [T/partner/player]).

%%
%% Question answering KB
%%
	 
:- public manner/2, be/2, okay/1, can/1, type/2.

okay($'Bruce').
be(player, $'Bruce').

declare_kind(player, actor).
