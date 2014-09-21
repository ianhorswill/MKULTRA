strategy(say_something,
	 command($me, $addressee,
		 tell_about($addressee, $me, Topic))) :-
   /pending_conversation_topics/ $addressee/Topic.

default_strategy(say_something,
		 null).

%%
%% Top-level strategies for responding to different kinds of dialog acts
%%

%%
%% Uninterpretable inputs
%%

default_strategy(respond_to_dialog_act(Act),
		 speech(["huh?"])) :-
   log(not_understood:Act).

%%
%% Greetings and closings
%%

strategy(respond_to_dialog_act(greet($addressee, $me)),
	 (assert(Conversation/greeted), greet($me, $addressee))) :-
   parent_concern_of($task, Conversation),
   \+ Conversation/greeted.
strategy(respond_to_dialog_act(greet($addressee, $me)),
	 null) :-
   parent_concern_of($task, Conversation),
   Conversation/greeted.

%%
%% Discourse increments
%%

strategy(respond_to_dialog_act(discourse_increment(_Sender, _Receiver, [ ])),
	 null).
strategy(respond_to_dialog_act(discourse_increment(Sender, Receiver, [ Act | Acts])),
	 ( respond_to_increment(Sender, Receiver, Act),
	   respond_to_dialog_act(discourse_increment(Sender, Receiver, Acts)) )).

default_strategy(respond_to_increment(_, _, _),
		 null).
strategy(respond_to_increment(Speaker, _, s(LF)),
	 respond_to_assertion(Speaker, LF)).

%%
%% Assertions
%%

strategy(respond_to_dialog_act(assertion(Speaker,_, LF, Tense, Aspect)),
	 respond_to_assertion(Speaker, Modalized)) :-
   modalized(LF, Tense, Aspect, Modalized).

default_strategy(respond_to_assertion(Speaker, ModalLF),
		 assert(/hearsay/Speaker/ModalLF)).

%%
%% Imperatives
%%

strategy(respond_to_dialog_act(command(_, $me, LF)),
	 follow_command(LF, Morality)) :-
   (@immoral(LF)) -> (Morality = immoral) ; (Morality = moral).
strategy(follow_command(LF, moral),
	 ( %assertion($me, $addressee, LF, future, simple),
	   LF )).
strategy(follow_command(_, immoral),
	 say_string("That would be immoral.")).

strategy(tell_about($me, $addressee, Topic),
	 describe(Topic, general)).

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

strategy(engage_in_conversation(Person, Topic),
	 ( add_conversation_topic(Person, Topic),
	   goto(Person),
	   greet($me, Person) )).

strategy(add_conversation_topic(Person, Topic),
	 S) :-
   var(Topic) ->
      S = null
      ;
      S = assert(/pending_conversation_topics/Person/Topic).

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