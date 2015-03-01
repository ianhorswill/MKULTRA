%%
%% Responding to imperatives
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
	 if(dialog_task(Task),
	    Task,
	    assert(/goals/pending_tasks/Task))).

:- public dialog_task/1.
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
