conversation >--> opening, content, closing.
opening >--> [greet(I, R), greet(R, I)].
content >--> [ ].
closing >--> { $script_concern/partner/Partner }, [exit_social_space(Partner)].
closing >--> [parting(I, R), parting(R, I)].

launch_conversation(Parent, Partner, Event) :-
   begin_child_concern(Parent, script, Child,
		       [ Child/partner/Partner,
			 Child/type:script:conversation,
			 Child/location_bids/Partner:200,
			 Child/history:[Event] ]).   