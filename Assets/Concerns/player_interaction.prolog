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

%%
%% Uninterpretable inputs
%%

default_strategy(player_input(_),
		 do_not_understand($me, player)).

%%
%% Imperatives
%%

strategy(player_input(command(player, $me, LF)),
	 follow_command(LF, Morality)) :-
   (@immoral(LF)) -> (Morality = immoral) ; (Morality = moral).
strategy(follow_command(LF, moral),
	 ( assertion($me, $addressee, LF, future, simple),
	   LF )).
strategy(follow_command(_, immoral),
	 say_string("That would be immoral.")).

strategy(go($me, Location),
	 goto(Location)).
strategy(take($me, Patient, _),
	 pickup(Patient)).
strategy(put($me, Patient, Destination),
	 move($me, Patient, Destination)) :-
   nonvar(Destination).

%%
%% Questions
%%

% Dispatch on question type
strategy(player_input(question(player, $me, Question, present, simple)),
	 S) :-
   (Question = Answer:Constraint) ->
      ( core_predication(Constraint, Core),
	S=answer_wh(Answer, Core, Constraint)
      )
      ;
      (S=answer_yes_no(Question)).

%% Yes/no quetsions
strategy(answer_yes_no(Q),
	 Answer) :-
   Q -> (Answer = agree($me, $addressee, Q)) ; (Answer = disagree($me, $addressee, Q)).

%% Wh-questions

default_strategy(answer_wh(Answer, _, Constraint),
		 enumerate_answers(Answer, Constraint)).

strategy(answer_wh(Identity, _, (be(Person, Identity), is_a(Person, person))),
	 introduce_person(Person)) :-
   character(Person).

strategy(answer_wh(Identity, _, (be(player, Identity), is_a(player, person))),
	 say(be(player, $me))).

strategy(answer_wh(M, _, manner(be($me), M)),
	 say(okay($me))).

default_strategy(enumerate_answers(Answer, Constraint),
	 answer_with_list(List, "and", Answer, Constraint)) :-
   all(Answer, Constraint, List).

strategy(enumerate_answers(Answer, can(Constraint)),
	 answer_with_list(List, "or", Answer, s(can(Constraint)))) :-
   all(Answer, can(Constraint), List).

strategy(answer_with_list([ ], _, Var, Constraint),
	 say_string(S)) :-
   !,
   begin(well_typed(Constraint, _, Bindings),
	 lookup_variable_type(Var, Kind, Bindings)),
   (kind_of(Kind, actor) -> S="Nobody"; S="Nothing").

strategy(answer_with_list(ItemList, Termination, Var, Constraint),
	 say_list(ItemList, Termination, Var^s(Core))) :-
   core_predication(Constraint, Core).

core_predication((P, is_a(_,_)), C) :-
   !,
   core_predication(P, C).
core_predication(P,P).

%%
%% Question answering KB
%%
	 
:- public manner/2, be/2, okay/1, can/1, type/2.

okay($'Bruce').
be(player, $'Bruce').

can(type(player, X)) :-
   player_command(X).
player_command("a question you want me to answer").
player_command("an action you want me to perform").
