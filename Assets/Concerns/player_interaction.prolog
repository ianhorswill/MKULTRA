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
strategy(answer_wh(Identity, be(Person, Identity)),
	 introduce_person(Person)) :-
   character(Person).
strategy(answer_wh(Identity, be(player, Identity)),
	 say(be(player, $'Bruce'))).

strategy(answer_wh(M, manner(be($'Bruce'), M)),
	 say(okay($'Bruce'))).

default_strategy(enumerate_answers(Answer, Constraint),
	 answer_with_list(List, "and", Answer, Constraint)) :-
   all(Answer, Constraint, List).

strategy(enumerate_answers(Answer, can(Constraint)),
	 answer_with_list(List, "or", Answer, s(can(Constraint)))) :-
   all(Answer, can(Constraint), List).

strategy(answer_with_list([], _, Var, Constraint),
	 say_string(S)) :-
   !,
   begin(well_typed(Constraint, _, Bindings),
	 lookup_variable_type(Var, Kind, Bindings)),
   (kind_of(Kind, actor) -> S="Nobody"; S="Nothing").

strategy(answer_with_list(ItemList, Termination, Var, Constraint),
	 say_list(ItemList, Termination, Var^s(Core))) :-
   core_predication(Constraint, Core).

core_predication((is_a(_,_), P), C) :-
   !,
   core_predication(P, C).
core_predication(P,P).


	 
:- public manner/2, be/2, okay/1, can/1, type/2.

okay($'Bruce').
be(player, $'Bruce').

can(type(player, X)) :-
   player_command(X).
player_command("a question you want me to answer").
player_command("an action you want me to perform").

person_name($'Bruce', "Bruce").