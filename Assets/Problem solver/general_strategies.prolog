%%
%% General strategies
%%

%% default_strategy(+Task, -Strategy) is nondet
%  Provides default strategies to use when Task has no specific matches.
strategy(resolve_match_failure(X), S) :-
   default_strategy(X, S).

%%
%% achieve(P)
%% Task to make P become true.
%%

strategy(achieve(P),
	 Task) :-
   postcondition(Task, P).

strategy(achieve(Condition),
	 null) :-
   % Don't have to do anything if condition is already true.
   Condition,
   !.

strategy(achieve(runnable(Action)),
	 achieve(Blocker)) :-
   blocking(Action, Blocker),
   \+ unachievable(Blocker).

%% unachievable(+Task)
%  Task is a-priori unachievable, so give up.
unachievable(exists(_)).

strategy(achieve(P),
	 wait_condition(P)) :-
   self_achieving(P).

%%
%% MOVEMENT AND LOCOMOTION
%% achieving locations
%% moving
%% docking
%% goto
%%

strategy(achieve(location(X,$me)),
	 pickup(X)).
strategy(achieve(location(X, Room)),
	 achieve(location(X, Container))) :-
   %\+ freestanding(X),
   is_a(Room, room),
   is_a(Container, work_surface),
   location(Container, Room).
strategy(achieve(location(X, Container)),
	 putdown(X, Container)) :-
   Container \= $me,
   \+ is_a(Container, room).

strategy(move($me, X,Y),
	 achieve(location(X, Y))).

strategy(achieve(docked_with(WorldObject)),
	 goto(WorldObject)).
strategy(goto(Target),
	 let(top_level_container(Target, Place),
	     begin(assert($task/location_bids/Place:Priority),
		   wait_event(arrived_at(Place)),
		   retract($task/location_bids/Place)))) :-
   assertion(atomic(Target), bad_target:goto(Target)),
   $task/priority:Priority.

normalize_task(bring($me, Recipient, Object),
	       move($me, Object, Recipient)).
normalize_task(give($me, Recipient, Object),
	       move($me, Object, Recipient)).
task_interacts_with_objects(bring(_, A, B), [A, B]).
task_interacts_with_objects(give(_, A, B), [A, B]).

guard_condition(Task, location(Object, _Loc)) :-
   task_interacts_with_objects(Task, Objects),
   member(Object, Objects).

%%
%% Spatial search
%%

normalize_task(search_for($me, Unspecified, Target),
	       search_for($me, CurrentRoom, Target)) :-
   var(Unspecified),
   in_room($me, CurrentRoom).
strategy(search_for($me, Container, Target),
	 search_container(Container, X^(X=Target),
			  X^mental_monologue(["Got it!"]),
			  mental_monologue(["Couldn't find it."]))) :-
   nonvar(Target).
strategy(search_for($me, Container, Target),
	 search_container(Container, X^previously_hidden(X),
			  X^mental_monologue(["Got ", np(X)]),
			  mental_monologue(["Nothing seems to be hidden."]))) :-
   var(Target).

strategy(search_container(Container, CriterionLambda, SuccessLambda, FailTask),
	 if(is_a(Container, room),
	    search_room(Container,
			CriterionLambda, SuccessLambda, FailTask),
	    search_nonroom(Container,
			   CriterionLambda, SuccessLambda, FailTask))).

strategy(search_room(Room, CriterionLambda, SuccessLambda, FailTask),
	  if(nearest(Container,
		     ( location(Container, Room),
		       \+ $task/searched/Container,
		       is_a(Container, container) )),
	     search_container(Container,
			      CriterionLambda,
			      SuccessLambda,
			      begin(assert($task/searched/Container),
				    mental_monologue(["Not here."]),
				    search_container(Room,
						     CriterionLambda,
						     SuccessLambda, FailTask))),
	     FailTask)).

strategy(search_nonroom(Container, CriterionLambda, SuccessLambda, FailTask),
	 begin(achieve(docked_with(Container)),
	       search_docked_container(CriterionLambda,
				       SuccessLambda, FailTask))) :-
   is_a(Container, container).

strategy(search_docked_container(Item^Criterion,
				 Item^SuccessTask,
				 FailTask),
	 if((location(Item, Container), Criterion),
	    SuccessTask,
	    search_for_hidden_items(Item^Criterion,
				    Item^SuccessTask,
				    FailTask) )) :-
   docked_with(Container).

strategy(search_for_hidden_items(CriterionLambda, SuccessLambda, FailTask),
	 if(reveal_hidden_item(_Item),
            begin(mental_monologue(["Wait, there's something here"]),
		  search_docked_container(CriterionLambda,
					  SuccessLambda,
					  FailTask)),
	    FailTask)).

:- public reveal_hidden_item/1.

reveal_hidden_item(Item) :-
   docked_with(Container),
   hidden_contents(Container, Item),
   reveal(Item),
   assert($task/previously_hidden_items/Item),
   % Don't wait for update loop to update Item's position.
   assert(/perception/location/Item:Container),
   !.

:- public previously_hidden/1.
previously_hidden(Item) :-
   $task/previously_hidden_items/Item.

%%
%% Ingestion (eating and drinking)
%%

strategy(eat($me, X),
	 ingest(X)).
postcondition(eat(_, X),
	      ~exists(X)).
postcondition(eat(Person, F),
	      ~hungry(Person)) :-
   existing(food, F).

strategy(drink($me, X),
	 ingest(X)).
postcondition(drink(_, X),
	      ~exists(X)).
postcondition(drink(Person, B),
	      ~thirsty(Person)) :-
   existing(beverage, B).

self_achieving(/perception/nobody_speaking).

%%
%% Social interaction
%%

strategy(engage_in_conversation(Person),
	 S) :-
   in_conversation_with(Person) ->
      S = null
      ;
      S = ( goto(Person),
	    greet($me, Person) ).

%%
%% OTHER
%% Sleeping
%%

strategy(sleep(Seconds),
	 wait_condition(after_time(Time))) :-
   Time is $now + Seconds.

strategy(examine($me, Object),
	 describe(Object, general, null)).

strategy(read($me, Object),
	 if(property_value(Object, text, Text),
	    say_string(Text),
	    say_string("It's blank."))).
