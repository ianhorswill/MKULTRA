conversation >--> opening, content, closing.
opening >--> [greet(I, R), greet(R, I)].
content >--> [ ].
closing >--> { $script_concern/partner/Partner }, [exit_social_space(Partner)].
closing >--> [parting(I, R), parting(R, I)].

launch_conversation(Parent, Partner, Event) :-
   launch_conversation(Parent, Partner, conversation, [Event]).

launch_conversation(Parent, Partner, Script, History) :-
   begin_child_concern(Parent, script, Child,
		       [ Child/partner/Partner,
			 Child/type:script:Script,
			 Child/history:History ]),
   (Partner \= $me -> assert(Child/location_bids/Partner:200);true).