%%
%% Discourse generation strategies for problem solver
%%

strategy(say_list([ ]),
	 say_string("Nothing")).
strategy(say_list([X]),
	 say_object(X)).
strategy(say_list([H | T]),
	 ( say_first(H),
	   say_rest(T) )) :-
   T \= [ ].

strategy(say_rest([H | T]),
	 ( say_next(H),
	   say_rest(T) )) :-
   T \= [ ].
strategy(say_rest([X]),
	 say_last(X)).

strategy(say_first(Object),
	 speech(
			     [ "well, there's ", np(Object), "," ])).
strategy(say_next(Object),
	 speech(
			     [ np(Object), "," ])).
strategy(say_last(Object),
	 speech(
			     [ "and", np(Object) ])).

strategy(say_object(Object),
	 speech(
			     [ np(Object) ])).
strategy(say_string(String),
	 speech(
			     [ String ])).
strategy(say(Assertion),
	 speech(
			     [ s(Assertion) ])).

strategy(speech(Items),
	 ( discourse_increment($me, $addressee, Items), sleep(1))).