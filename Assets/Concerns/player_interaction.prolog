%%%
%%% Driver for conversation between player and player character
%%%

on_enter_state(start, player_interaction, C) :-
   launch_conversation(C, $me, player_interaction_script, [ ]).

player_interaction_script >-->
   [ prompt_player($me, $me) ],
   player_dialog.

player_dialog >-->
   [ player_input(_), apology($me, $me) ],
   player_dialog.
