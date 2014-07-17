%%%
%%% Driver for conversation between player and player character
%%%

on_enter_state(start, player_interaction, C) :-
   launch_conversation(C, player, player_interaction_script, [ ]).

player_interaction_script >-->
   player_dialog.

player_dialog >-->
   [ player_input(I) ],
   { player_input_response(I, R)  },
   [ R ],
   player_dialog.

:- public player_input_response/2.

player_input_response(question(player, $me, Question, T, A),
		      assertion($me, player, Answer, T, A)) :-
   answer_to(Question, Answer).
player_input_response(command(player, $me, LF),
		      assertion($me, player, LF, future, simple)) :-
   task_form(LF, Task),
   start_task($script_concern, Task, 100).

task_form(go($me, X), goto(X)).

answer_to(M:manner(be($'Bruce'), M), okay($'Bruce')) :-
   !.
answer_to(_X:Y, Y) :-
   !, Y.
answer_to(Y, Y) :-
   Y, !.
answer_to(Y, not(Y)).

:- public manner/2, be/2, okay/1.

okay($'Bruce').
be($'Bruce', $'Bruce').
be(player, $'Bruce').
