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
strategy(goto(Object),
	 ( let(top_level_container(Object, Place),
	       ( assert($task/location_bids/Place:Priority),
		 wait_event(arrived_at(Place)),
		 retract($task/location_bids/Place)) ) )) :-
   $task/priority:Priority.

strategy(bring($me, Recipient, Object),
	 move($me, Object, Recipient)).
strategy(give($me, Recipient, Object),
	 move($me, Object, Recipient)).
task_interacts_with_objects(bring(_, A, B), [A, B]).
task_interacts_with_objects(give(_, A, B), [A, B]).

guard_condition(Task, location(Object, _Loc)) :-
   task_interacts_with_objects(Task, Objects),
   member(Object, Objects).

%%
%% Spatial search
%%

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

strategy(search_container(Room, CriterionLambda, SuccessLambda, FailTask),
	 S) :-
   is_a(Room, room),
   ( nearest(Container,
	     ( location(Container, Room),
	       \+ $task/searched/Container,
	       is_a(Container, container) )) ->
       S = search_container(Container,
			    CriterionLambda,
			    SuccessLambda,
			    ( assert($task/searched/Container),
			      mental_monologue(["Not here."]),
			      search_container(Room,
					       CriterionLambda,
					       SuccessLambda, FailTask)))
       ;
       S = FailTask ).

strategy(search_container(Container, CriterionLambda, SuccessLambda, FailTask),
	 ( achieve(docked_with(Container)),
	   search_docked_container(CriterionLambda, SuccessLambda, FailTask) )
	) :-
   is_a(Container, container),
   \+ is_a(Container, room).

strategy(search_docked_container(Item^Criterion,
				 Item^SuccessTask,
				 FailTask),
	 S) :-
   docked_with(Container),
   once(((location(Item, Container), Criterion) ->
        S = SuccessTask
        ;
        S = search_for_hidden_items(Item^Criterion,
				    Item^SuccessTask,
				    FailTask) )).

strategy(search_for_hidden_items(CriterionLambda, SuccessLambda, FailTask),
	 S) :-
   reveal_hidden_item(_Item) ->
        S = ( mental_monologue(["Wait, there's something here"]),
	      search_docked_container(CriterionLambda,
				      SuccessLambda,
				      FailTask) )
        ;
	S = FailTask.

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

