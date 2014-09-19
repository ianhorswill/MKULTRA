launch_conversation(Parent, Partner, Event) :-
   begin_child_concern(Parent, conversation, 1, Child,
		       [ Child/partner/Partner,
			 Child/initial_history/Event ]),
   (Partner \= player -> assert(Child/location_bids/Partner:200);true).

conversation_handler_task(Concern, Input) :-
   kill_children(Concern),
   Concern/partner/P,
   start_task(Concern, Input, 100, T, [T/partner/P]).

:- public still_speaking_to_me/1.
still_speaking_to_me(Partner) :-
   elroot(Partner, Root),
   descendant_concern_of(Root, C),
   C/type:conversation,
   C/partner/ $me,
   C/concerns/_.