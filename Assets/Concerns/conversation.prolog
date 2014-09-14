conversation >--> opening, content, closing.
opening >--> [greet(I, R), greet(R, I)].
content >--> [ ].
closing >-->
   somebody_leaves,
   { conversation_participants(I, R) },
   [parting(I, R), parting(R, I)].

somebody_leaves >-->
   { $script_concern/partner/Partner },
   [exit_conversational_space(Partner)].

somebody_leaves >-->
   [exit_conversational_space($me)].

:- public conversation_participants/2.
conversation_participants($me, Partner) :-
   $script_concern/partner/Partner.
conversation_participants(Partner, $me) :-
   $script_concern/partner/Partner.

launch_conversation(Parent, Partner, Event) :-
   launch_conversation(Parent, Partner, conversation, [Event]).

launch_conversation(Parent, Partner, Script, History) :-
   begin_child_concern(Parent, script, 1, Child,
		       [ Child/partner/Partner,
			 Child/type:script:Script,
			 Child/initial_history:History]),
   (Partner \= player -> assert(Child/location_bids/Partner:200);true).