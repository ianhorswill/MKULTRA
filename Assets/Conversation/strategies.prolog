:- external explanation/2.

strategy(say_something,
	 begin(retract(TopicNode),
	       if(string(Topic),
		  speech([Topic]),
		  Topic))) :-
   % Need the once to prevent it from generating all topics at once.
   once(/pending_conversation_topics/ $addressee/Topic>>TopicNode).

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
