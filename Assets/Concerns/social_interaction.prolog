standard_concern(social_interaction).

on_event(greet(Speaker, $me),
	 social_interaction, SocialInteraction,
	 begin_child_concern(SocialInteraction, conversation, Child,
			[ Child/partner/Speaker,
			  Child/heard_greeting,
			  Child/last_dialog:dialog(Speaker, $this, greeting) ])
	) :-
    \+(SocialInteraction/concerns/_/partner/Speaker).

on_event(greet($me, Target),
	 social_interaction, SocialInteraction,
	 begin_child_concern(SocialInteraction, conversation, Child,
			[ Child/partner/Target,
			  Child/said_greeting,
			  Child/last_dialog:dialog($me, Target, greeting) ])) :-
    \+(SocialInteraction/concerns/_/partner/Target).


