%%%
%%% Driver for conversation between player and player character
%%%

on_event(player_input(DialogAct),
	 player_interaction,
	 C,
	 Response) :-
   once(player_input_response(DialogAct, C, Response)).


player_input_response(DialogAct, C, player_input_task(C, respond_to_dialog_act(Normalized))) :-
   normalize_dialog_act(DialogAct, Normalized),
   agent(Normalized, player).
player_input_response(X, C, assert(C/propose_action:X)).

da_normal_form(assertion($pc, NPC, knows(NPC, Proposition), present, simple),
	       hypno_command($pc, NPC, Proposition, present, simple)).
da_normal_form(command($pc, NPC, knows(NPC, Proposition)),
	       hypno_command($pc, NPC, Proposition, present, simple)).
da_normal_form(command($pc, NPC, believe(NPC, Proposition)),
	       hypno_command($pc, NPC, Proposition, present, simple)).

on_event(DialogAct,
	 player_interaction,
	 C,
	 retract(C/propose_action)) :-
   C/propose_action:A,
   A=DialogAct.

propose_action(A, player_interaction, C) :-
   C/propose_action:A.

:- public player_input_task/2.

player_input_task(Concern, Input) :-
   kill_children(Concern),
   start_task(Concern, Input, 100, T, [T/partner/player]),
   restart_everyday_life_task.

%%
%% Question answering KB
%%
	 
:- public manner/2, be/2, okay/1, can/1, type/2.

okay($pc).
be(player, $pc).

declare_kind(player, actor).
