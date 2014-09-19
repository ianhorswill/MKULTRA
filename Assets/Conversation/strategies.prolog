%%
%% Uninterpretable inputs
%%

default_strategy(respond_to_dialog_act(Act),
		 speech(["huh?"])) :-
   log(not_understood:Act).

%%
%% Discourse increments
%%

strategy(respond_to_dialog_act(discourse_increment(_Sender, _Receiver, _Acts)),
	 null).

%%
%% Assertions
%%

strategy(respond_to_dialog_act(assertion(_,_, LF, Tense, Aspect)),
	 respond_to_assertion(LF, Tense, Aspect)).

default_strategy(respond_to_assertion(_, _, _),
		 null).

%%
%% Imperatives
%%

strategy(respond_to_dialog_act(command(_, $me, LF)),
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

strategy(talk($me, $addressee, Topic),
	 describe(Topic, introduction)) :-
   nonvar(Topic).

strategy(talk($me, ConversationalPartner, Topic),
	 engage_in_conversation(ConversationalPartner, Topic)) :-
   ConversationalPartner \= $addressee.

strategy(engage_in_conversation(Person, _Topic),
	 ( goto(Person), greet($me, Person) )).

%%
%% Questions
%%

% Dispatch on question type
strategy(respond_to_dialog_act(question(_, $me, Question, present, simple)),
	 S) :-
   (Question = Answer:Constraint) ->
      ( lf_main_predicate(Constraint, Core),
	S=answer_wh(Answer, Core, Constraint)
      )
      ;
      (S=answer_yes_no(Question)).

%% Yes/no quetsions
strategy(answer_yes_no(Q),
	 Answer) :-
   Q -> (Answer = agree($me, $addressee, Q)) ; (Answer = disagree($me, $addressee, Q)).

%% Wh-questions

default_strategy(answer_wh(Answer, Core, Constraint),
		 enumerate_answers(Answer, Core, Constraint)).

strategy(answer_wh(Identity, _, (be(Person, Identity), is_a(Person, person))),
	 introduce_person(Person)) :-
   character(Person).

strategy(answer_wh(Identity, _, (be(player, Identity), is_a(player, person))),
	 say(be(player, $me))).

strategy(answer_wh(Answer, can(Action), Constraint),
	 answer_with_list(List, "or", Type, (can(Action), is_a(Answer, Type)))) :-
   possible_types_given_constraint(Answer, Constraint, List).

strategy(answer_wh(M, _, manner(be($me), M)),
	 say(okay($me))).

default_strategy(enumerate_answers(Answer, Core, Constraint),
	 answer_with_list(List, Connective, Answer, Core)) :-
   nonvar(Constraint),
   all(Answer, Constraint, List),
   connective_for_answer(Constraint, Connective).

connective_for_answer((can(_), _), "or") :- !.
connective_for_answer(_, "and").

strategy(answer_with_list([ ], _, Var, Constraint),
	 say_string(S)) :-
   !,
   begin(variable_type_given_constraint(Var, Constraint, Kind)),
   (kind_of(Kind, actor) -> S="Nobody"; S="Nothing").

strategy(answer_with_list(ItemList, Termination, Var, Constraint),
	 say_list(ItemList, Termination, Var^s(Constraint))).

%%
%% Hypnotic commands
%%

strategy(respond_to_dialog_act(hypno_command(_, $me, LF, present, simple)),
	 call(hypnotically_believe(LF))).