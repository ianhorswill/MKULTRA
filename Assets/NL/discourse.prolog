%%
%% Discourse generation strategies for problem solver
%%

strategy(introduce_person(Person),
	 ( say(be(Person, Name)),
	   describe(Person) )
	) :-
   person_name(Person, Name).

%%
%% Describing objects
%%

strategy(describe(Object),
	 describe_properties(Object, Properties)) :-
   all(Prop:Value,
       ( property_value(Object, Prop, Value),
	 property_interesting_to($addressee, Object, Prop, Value) ),
       Properties).

property_interesting_to(_, _, _, _).

strategy(describe_properties(Object, Properties),
	 generate_list(Properties, property_of(Object))).

strategy(generate_next(Property:Value, property_of(Object)),
	 describe_property("", Object, Property, Value, ", ...")).
strategy(generate_last(Property:Value, property_of(Object)),
	 describe_property("and", Object, Property, Value, ".")).

strategy(describe_property(Linkage, Object, Property, Value, Termination),
	 speech([Linkage, Surface, Termination])) :-
   surface_form(property_value(Object, Property, Value), Surface).

surface_form(property_value(Object, Property, Value),
	     s(be(Object, Value))) :-
   copular_property(Property).

%%
%% Enumerating lists
%% To use this, call the task generate_list(List, Generator), where the
%% list is what you want to generate, and Generator is whatever information
%% is needed to keep track of how to generate items.  Then supply strategies
%% for your generator for:
%%   generate_empty(Generator)                   The list is empty
%%   generate_singleton(Item, Generator)         The list has exactly one item
%%   generate_first/next/last(Item, Generator)   Generate an item
%%

strategy(generate_list([ ], Generator),
	 generate_empty(Generator)).
strategy(generate_list([X], Generator),
	 generate_singleton(X, Generator)).
strategy(generate_list([H | T], Generator),
	 ( generate_first(H, Generator),
	   generate_rest(T, Generator) )) :-
   T \= [ ].

strategy(generate_rest([H | T], Generator),
	 ( generate_next(H, Generator),
	   generate_rest(T, Generator) )) :-
   T \= [ ].
strategy(generate_rest([X], Generator),
	 generate_last(X, Generator)).

default_strategy(generate_empty(_),
		 null).
default_strategy(generate_singleton(Item, Generator),
		 generate_next(Item, Generator)).
default_strategy(generate_first(Item, Generator),
		 generate_next(Item, Generator)).
default_strategy(generate_last(Item, Generator),
		 generate_next(Item, Generator)).


%%
%% Saying lists of objects
%% This should get converted to use generate_list/2 at some point.
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

%%
%% Utilities
%%
reduce(Lambda, Arg, Result) :-
   copy_term(Lambda, Copy),
   reduce_aliasing(Copy, Arg, Result).

reduce_aliasing(Arg^Result, Arg, Result).