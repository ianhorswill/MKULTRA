:- external explanation/2.

strategy(say_something,
	 ( retract(TopicNode),
	   Topic )) :-
   /pending_conversation_topics/ $addressee/Topic>>TopicNode.

default_strategy(say_something,
		 null).

strategy(ask_about($me, $addressee, $addressee),
	 question($me, $addressee,
		  X:manner(be($addressee), X),
		  present, simple)).
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
strategy(respond_to_increment(Speaker, Addressee, s(LF)),
	 respond_to_dialog_act(assertion(Speaker, Addressee, LF, present, simple))).

%%
%% Assertions
%%

strategy(respond_to_dialog_act(assertion(Speaker,_, LF, Tense, Aspect)),
	 respond_to_assertion(Speaker, Modalized, Truth)) :-
   modalized(LF, Tense, Aspect, Modalized),
   admitted_truth_value(Speaker, Modalized, Truth).

strategy(respond_to_assertion(_Speaker, _ModalLF, true),
	 say_string("Yes, I know.")).
strategy(respond_to_assertion(_Speaker, _ModalLF, false),
	 say_string("I don't think so.")).
strategy(respond_to_assertion(Speaker, ModalLF, unknown),
	 (say_string(Response), assert(/hearsay/Speaker/ModalLF))) :-
   heard_hearsay(ModalLF) -> Response="I've head that." ; Response="Really?".

heard_hearsay(ModalLF) :-
   /hearsay/_/Assertion, Assertion=ModalLF.


%%
%% Imperatives
%%

strategy(respond_to_dialog_act(command(Requestor, $me, Task)),
	 follow_command(Task, RequestStatus)) :-
   request_status(Requestor, Task, RequestStatus).

request_status(_Requestor, Task, immoral) :-
   @immoral(Task),
   !.
request_status(_Requestor, Task, non_normative) :-
   \+ well_typed(Task, action, _),
   !.
request_status(_Requestor, Task, unachievable) :-
   \+ have_strategy(Task),
   !.
request_status(Requestor, Task, incriminating(P)) :-
   guard_condition(Task, P),
   pretend_truth_value(Requestor, P, Value),
   Value \= true,
   !.
request_status(_Requestor, _Task, normal).

strategy(follow_command(Task, normal),
	 Strategy) :-
   dialog_task(Task) ->
      (Strategy = Task)
      ;
      (Strategy = assert(/goals/pending_tasks/Task)).

dialog_task(tell_about(_,_,_)).

strategy(follow_command(_, immoral),
	 say_string("That would be immoral.")).
strategy(follow_command(_, non_normative),
	 say_string("That would be weird.")).
strategy(follow_command(_, unachievable),
	 say_string("I don't know how.")).
strategy(follow_command(_, incriminating(_)),
	 say_string("Sorry, I can't.")).

strategy(tell_about($me, _, Topic),
	 describe(Topic, general, speech(["Sorry; don't know anything."]))).

strategy(go($me, Location),
	 goto(Location)).
strategy(take($me, Patient, _),
	 pickup(Patient)).
strategy(put($me, Patient, Destination),
	 move($me, Patient, Destination)) :-
   nonvar(Destination).

strategy(talk($me, $addressee, Topic),
	 describe(Topic, introduction,
		  say(["Sorry, I don't know anything"]))) :-
   nonvar(Topic).

strategy(talk($me, ConversationalPartner, Topic),
	 add_conversation_topic(ConversationalPartner, Topic)) :-
   ConversationalPartner \= $addressee.

strategy(add_conversation_topic(Person, Topic),
	 assert(/pending_conversation_topics/Person/ask_about($me,
							      Person,
							      Topic))) :-
   var(Topic) -> Topic = Person ; true.

strategy(end_game(_,_), end_game(null)).

%%
%% Questions
%%

% Dispatch on question type
strategy(respond_to_dialog_act(question(Asker, $me, Question,
					present, _Aspect)),
	 S) :-
   (Question = Answer:Constraint) ->
      ( lf_main_predicate(Constraint, Core),
	S=answer_wh(Asker, Answer, Core, Constraint)
      )
      ;
      (S=answer_yes_no(Asker, Question)).

%% Yes/no quetsions
strategy(answer_yes_no(Asker, Q),
	 generate_answer(Q, Answer)) :-
   admitted_truth_value(Asker, Q, Answer).

strategy(generate_answer(Q, true),
	 agree($me, $addressee, Q)).
strategy(generate_answer(Q, false),
	 disagree($me, $addressee, Q)).
strategy(generate_answer(_Q, unknown),
	 speech(["Don't know."])).


%% Wh-questions

default_strategy(answer_wh(Asker, Answer, Core, Constraint),
		 S) :-
   unique_answer(Answer, Core) ->
      S = generate_unique_answer(Asker, Answer, Core, Constraint)
      ;
      S = enumerate_answers(Asker, Answer, Core, Constraint).

strategy(answer_wh(_Asker, Identity, _,
		   (be(Person, Identity), is_a(Person, person))),
	 introduce_person(Person)) :-
   character(Person).

strategy(answer_wh(_Asker, Identity, _,
		   (be(player, Identity), is_a(player, person))),
	 say(be(player, $me))).

strategy(answer_wh(_Asker, Answer, can(Action), Constraint),
	 answer_with_list(List, "or", Type,
			  (can(Action), is_a(Answer, Type)))) :-
   possible_types_given_constraint(Answer, Constraint, List).

strategy(answer_wh(M, _,
		   manner(be(Who), M),
		   _),
	 say(okay(Who))).

strategy(answer_wh(Asker, Explanation, explanation(P, Explanation), _),
	 S) :-
   admitted_truth_value(Asker, P, true) ->
      (admitted_truth_value(Asker, explanation(P, E), true) ->
         (S = assertion($me, Asker, E, present, simple))
         ;
         (S = speech(["I couldn't speculate."])))
      ;
      (S = assertion($me, Asker, not(P), present, simple)).

default_strategy(generate_unique_answer(Asker, _Answer, Core, Constraint),
		 S) :-
   nonvar(Constraint),
   $task/partner/Partner,
   admitted_truth_value(Asker, Constraint, Truth),
   ( (Truth = true) ->
        S = assertion($me, Partner, Core, present, simple)
        ;
        S = speech(["Don't know"]) ).

default_strategy(enumerate_answers(Asker, Answer, Core, Constraint),
	 answer_with_list(List, Connective, Answer, Core)) :-
   nonvar(Constraint),
   all(Answer, admitted_truth_value(Asker, Constraint, true), List),
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
	 ( flash(Yellow, Green, 0.3, 1.5),
	   assertion($me, Partner, LF, present, simple) )) :-
   hypnotically_believe(LF),
   Yellow is $'Color'.yellow,
   Green is $'Color'.green,
   $task/partner/Partner.

default_strategy(do_hypnotically_believe(_LF),
		 % No effect
		 null).