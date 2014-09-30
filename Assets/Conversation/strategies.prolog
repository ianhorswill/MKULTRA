strategy(say_something,
	 ( retract(TopicNode),
	   Topic )) :-
   /pending_conversation_topics/ $addressee/Topic>>TopicNode.

default_strategy(say_something,
		 null).

strategy(ask_about($me, $addressee, $addressee),
	 question($me, $addressee, X:manner(be($addressee), X))).
strategy(ask_about($me, $addressee, Topic),
	 command($me, $addressee,
		 tell_about($addressee, $me, Topic))) :-
   Topic \= $addressee.
strategy(ask_about($me, Who, Topic),
	 add_conversation_topic(Who, Topic)) :-
   Who \= $addressee.

%%
%% Top-level strategies for responding to different kinds of dialog acts
%%

strategy(respond_to_dialog_act(parting(Them, $me)),
	 ( assert(Parent/generated_parting),
	   parting($me, Them),
	   sleep(1),
	   call(kill_concern(Parent)) )) :-
   parent_concern_of($task, Parent),
   \+ Parent/generated_parting.

strategy(respond_to_dialog_act(parting(_Them, $me)),
	 ( call(kill_concern(Parent)) )) :-
   parent_concern_of($task, Parent),
   Parent/generated_parting.

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

strategy(respond_to_dialog_act(command(Requestor, $me, LF)),
	 follow_command(LF, RequestStatus)) :-
   request_status(Requestor, LF, RequestStatus).

request_status(_Requestor, LF, immoral) :-
   @immoral(LF),
   !.
request_status(_Requestor, LF, non_normative) :-
   \+ well_typed(LF, action, _),
   !.
request_status(_Requestor, _LF, normal).

strategy(follow_command(LF, normal),
	 ( %assertion($me, $addressee, LF, future, simple),
	   LF )).
strategy(follow_command(_, immoral),
	 say_string("That would be immoral.")).
strategy(follow_command(_, non_normative),
	 say_string("That would be weird.")).

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
	 add_conversation_topic(ConversationalPartner, Topic)) :-
   ConversationalPartner \= $addressee.

strategy(add_conversation_topic(Person, Topic),
	 assert(/pending_conversation_topics/Person/ask_about($me,
							      Person,
							      Topic))) :-
   var(Topic) -> Topic = Person ; true.

%%
%% Questions
%%

% Dispatch on question type
strategy(respond_to_dialog_act(question(Asker, $me, Question, present, simple)),
	 S) :-
   (Question = Answer:Constraint) ->
      ( lf_main_predicate(Constraint, Core),
	S=answer_wh(Answer, Core, Constraint)
      )
      ;
      (S=answer_yes_no(Asker, Question)).

:- external cover_story/3.

%% Yes/no quetsions
strategy(answer_yes_no(Asker, Q),
	 generate_answer(Q, Answer)) :-
   yn_question_answer(Asker, Q, Answer).

yn_question_answer(Asker, Q, Answer) :-
   cover_story(Asker, Q, Answer),
   !.
yn_question_answer(_Asker, Q, Answer) :-
   Q -> Answer=yes ; Answer=no.

strategy(generate_answer(Q, yes),
	 agree($me, $addressee, Q)).
strategy(generate_answer(Q, no),
	 disagree($me, $addressee, Q)).
strategy(generate_answer(_Q, unknown),
	 speech(["Don't know."])).


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
%% Agreement/disagreement
%%

strategy(respond_to_dialog_act(agree(_, _, _)),
	 null).
strategy(respond_to_dialog_act(disagree(_, _, _)),
	 null).

%%
%% Hypnotic commands
%%

strategy(respond_to_dialog_act(hypno_command(_, $me, LF, present, simple)),
	 do_hypnotically_believe(LF)).

strategy(do_hypnotically_believe(LF),
	 flash(Yellow, Green, 0.3, 1.5)) :-
   hypnotically_believe(LF),
   Yellow is $'Color'.yellow,
   Green is $'Color'.green.

default_strategy(do_hypnotically_believe(_LF),
		 % No effect
		 null).