%%
%% Discourse generation strategies for problem solver
%%

strategy(introduce_person(Person),
	 ( maybe_give_name(Person),
	   describe(Person, introduction, null) )
	).

strategy(maybe_give_name($me),
	 say(be($me, Name))) :-
   property_value($me, given_name, Name).

strategy(maybe_give_name(X),
	 null) :-
   X \= $me.

property_relevant_to_purpose(introduction, _, Property, _) :-
   memberchk(Property, [age, gender, job]).

relation_relevant_to_purpose(introduction, _, Relation, _) :-
   memberchk(Relation, [ interested_in, knows_about, roommate_of ]).

%%
%% Describing objects
%%

strategy(describe(Object, Purpose, NullContinuation),
	 describe_attributes(Object, Attributes, NullContinuation)) :-
   all(Attribute,
       interesting_attribute(Purpose, Object, Attribute),
       AllAttributes),
   remove_redundant_attributes(AllAttributes, Attributes).

remove_redundant_attributes([ ], [ ]).
remove_redundant_attributes([Relation/Relatum | Rest], RestRemoved) :-
   decendant_relation(Antecedant, Relation),
   member(Antecedant/Relatum, Rest),
   !,
   remove_redundant_attributes(Rest, RestRemoved).
remove_redundant_attributes([X | Rest], [X | Final]) :-
   remove_implicants(X, Rest, WithoutImplicants),
   remove_redundant_attributes(WithoutImplicants, Final).

remove_implicants(_, [ ], [ ]).
remove_implicants(Rel/Object, [Implicant/Object | Rest], Rest) :-
   ancestor_relation(Implicant, Rel),
   !.
remove_implicants(Attribute, [X | Rest] , [X | RestRemoved]) :-
   remove_implicants(Attribute, Rest, RestRemoved).


interesting_attribute(Purpose, Object, Attribute) :-
   interesting_property(Purpose, Object, Attribute)
   ;
   interesting_relation(Purpose, Object, Attribute).

interesting_property(Purpose, Object, Prop:Value) :-
   property_nondefault_value(Object, Prop, Value),
   \+ /mentioned_to/ $addressee /Object/Prop:Value,
   property_relevant_to_purpose(Purpose, Object, Prop, Value).

interesting_relation(Purpose, Object, Relation/Relatum) :-
   related_nondefault(Object, Relation, Relatum),
   \+ /mentioned_to/ $addressee /Object/Relation/Relatum,
   relation_relevant_to_purpose(Purpose, Object, Relation, Relatum).

strategy(describe_attributes(_Object, [], NullContinuation),
	 NullContinuation).
strategy(describe_attributes(Object, Attributes, _NullK),
	 generate_list(Attributes, attribute_of(Object))) :-
   Attributes \= [ ].

strategy(generate_next(Property:Value, attribute_of(Object)),
	 describe_property("", Object, Property, Value, ", ...")).
strategy(generate_last(Property:Value, attribute_of(Object)),
	 describe_property("and", Object, Property, Value, ".")).

strategy(generate_next(Property/Value, attribute_of(Object)),
	 describe_relation("", Object, Property, Value, ", ...")).
strategy(generate_last(Property/Value, attribute_of(Object)),
	 describe_relation("and", Object, Property, Value, ".")).

strategy(describe_property(Linkage, Object, Property, Value, Termination),
	 speech([Linkage, Surface, Termination])) :-
   surface_form(property_value(Object, Property, Value), Surface),
   assert(/mentioned_to/ $addressee /Object/Property:Value).

strategy(describe_relation(Linkage, Object, Relation, Relatum, Termination),
	 speech([Linkage, Surface, Termination])) :-
   surface_form(related(Object, Relation, Relatum), Surface),
   forall(ancestor_relation(A, Relation),
	  assert(/mentioned_to/ $addressee /Object/A/Relatum)).

surface_form(property_value(Object, Property, Value),
	     s(property_value(Object, Property, Value))).

surface_form(related(Object, Relation, Relatum),
	     s(related(Object, Relation, Relatum))).

%%
%% Enumerating lists
%% To use this, call the task generate_list(List, GenerationInfo), where the
%% list is what you want to generate, and GenerationInfo is whatever information
%% is needed to keep track of how to generate items.  Then supply strategies
%% for your generator for:
%%   generate_empty(GenerationInfo)                   The list is empty
%%   generate_singleton(Item, GenerationInfo)         The list has exactly one item
%%   generate_first/next/last(Item, GenerationInfo)   Generate an item
%%

strategy(generate_list([ ], GenerationInfo),
	 generate_empty(GenerationInfo)).
strategy(generate_list([X], GenerationInfo),
	 generate_singleton(X, GenerationInfo)).
strategy(generate_list([H | T], GenerationInfo),
	 ( generate_first(H, GenerationInfo),
	   generate_rest(T, GenerationInfo) )) :-
   T \= [ ].

strategy(generate_rest([H | T], GenerationInfo),
	 ( generate_next(H, GenerationInfo),
	   generate_rest(T, GenerationInfo) )) :-
   T \= [ ].
strategy(generate_rest([X], GenerationInfo),
	 generate_last(X, GenerationInfo)).

default_strategy(generate_empty(_),
		 null).
default_strategy(generate_singleton(Item, GenerationInfo),
		 generate_next(Item, GenerationInfo)).
default_strategy(generate_first(Item, GenerationInfo),
		 generate_next(Item, GenerationInfo)).
default_strategy(generate_last(Item, GenerationInfo),
		 generate_next(Item, GenerationInfo)).


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
	 speech([ Termination, np(Object), "."])).
strategy(say_object(Object),
	 speech([ np(Object) ])).
strategy(say_string(String),
	 speech([ String ])).
strategy(say(Assertion),
	 speech([ s(Assertion) ])).

strategy(speech(Items),
	 ( discourse_increment($me, $addressee, Items), sleep(1))) :-
   $task/partner/player.
strategy(speech(Items),
	 ( wait_condition(/perception/nobody_speaking), discourse_increment($me, $addressee, Items))) :-
   assertion($task/partner/P, $me:"Conversation partner undefined."),
   P \= player.

strategy(mental_monologue(Items),
	 (discourse_increment($me, $me, Items), sleep(1))).

%%
%% Utilities
%%
reduce(Lambda, Arg, Result) :-
   copy_term(Lambda, Copy),
   reduce_aliasing(Copy, Arg, Result).

reduce_aliasing(Arg^Result, Arg, Result).