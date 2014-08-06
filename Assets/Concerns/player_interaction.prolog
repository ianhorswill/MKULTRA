%%%
%%% Driver for conversation between player and player character
%%%

on_event(player_input(X),
	 player_interaction,
	 C,
	 player_input_task(C, player_input(X))).

player_input_task(Concern, Input) :-
   kill_children(Concern),
   start_task(Concern, Input, 100, T, [T/partner/player]).

default_strategy(player_input(_),
		 do_not_understand($me, player)).

strategy(player_input(command(player, $me, LF)),
	 follow_command(LF)).
strategy(follow_command(LF),
	 ( assertion($me, $addressee, LF, future, simple),
	   LF )).

strategy(go($me, Location),
	 goto(Location)).
strategy(take($me, Patient, _),
	 pickup(Patient)).
strategy(put($me, Patient, Destination),
	 move($me, Patient, Destination)) :-
   nonvar(Destination).

strategy(player_input(question(player, $me, Question, present, simple)),
	 S) :-
   (Question = Answer:Constraint) -> (S=answer_wh(Answer, Constraint)) ; (S=answer_yes_no(Question)).

strategy(answer_yesno(Q),
	 Answer) :-
   Q -> (Answer = agree($me, $addressee, Q)) ; (Answer = disagree($me, $addressee, Q)).

default_strategy(answer_wh(Answer, Constraint),
		 enumerate_answers(Answer, Constraint)).
strategy(answer_wh(M, manner(be($'Bruce'), M)),
	 say(okay($'Bruce'))).

strategy(enumerate_answers(Answer, Constraint),
	 answer_with_list(List)) :-
   all(Answer, Constraint, List),
   log(list:List).
strategy(answer_with_list(List),
	 say_list(List)).	
	 
:- public manner/2, be/2, okay/1, can/1, type/2.

okay($'Bruce').
be($'Bruce', "Bruce").
be(player, $'Bruce').

can(type(player, X)) :-
   player_command(X).
player_command("a question you want me to answer").

