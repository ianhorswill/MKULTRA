standard_concern(social_interaction).

on_event(greet(Speaker, Me),
	 social_interaction, SocialInteraction,
	 begin_child_concern(SocialInteraction, conversation, Child,
			[ Child/partner/Speaker,
			  Child/heard_greeting,
			  Child/last_dialog:dialog(Speaker, $this, greeting) ])
	) :-
    Me is $game_object,
    \+(SocialInteraction/concerns/_/partner/Speaker).

on_event(greet(Me, Target),
	 social_interaction, SocialInteraction,
	 begin_child_concern(SocialInteraction, conversation, Child,
			[ Child/partner/Target,
			  Child/said_greeting,
			  Child/last_dialog:dialog(Me, Target, greeting) ])) :-
    Me is $game_object,
    \+(SocialInteraction/concerns/_/partner/Target).


