%%
%% Discourse generation strategies for problem solver
%%

strategy(say_list([ ], _, _),
	 say_string("Nothing")).
strategy(say_list([X], _, SurfaceLambda),
	 speech([Surface])) :-
   reduce(SurfaceLambda, X, Surface).
strategy(say_list([H | T], Termination, SurfaceLambda),
	 ( say_first(H, SurfaceLambda),
	   say_rest(T, Termination, SurfaceLambda) )) :-
   T \= [ ].

strategy(say_rest([H | T], Termination, SurfaceLambda),
	 ( say_next(H),
	   say_rest(T, Termination, SurfaceLambda) )) :-
   T \= [ ].
strategy(say_rest([X], Termination, SurfaceLambda),
	 say_last(X, Termination, SurfaceLambda)).

strategy(say_first(Object, SurfaceLambda),
	 speech([ Surface, "," ])) :-
   reduce(SurfaceLambda, Object, Surface).
strategy(say_next(Object),
	 speech([ np(Object), "," ])).
% strategy(say_last(Object, Termination, SurfaceLambda),
% 	 speech([ Termination, Surface ])) :-
%    reduce(SurfaceLambda, Object, Surface).
strategy(say_last(Object, Termination, _SurfaceLambda),
	 speech([ Termination, np(Object)])).
strategy(say_object(Object),
	 speech([ np(Object) ])).
strategy(say_string(String),
	 speech([ String ])).
strategy(say(Assertion),
	 speech([ s(Assertion) ])).

strategy(speech(Items),
	 ( discourse_increment($me, $addressee, Items), sleep(1))).

strategy(introduce_person(Person),
	 say(be(Person, Name))) :-
   person_name(Person, Name).

reduce(Lambda, Arg, Result) :-
   copy_term(Lambda, Copy),
   reduce_aliasing(Copy, Arg, Result).

reduce_aliasing(Arg^Result, Arg, Result).