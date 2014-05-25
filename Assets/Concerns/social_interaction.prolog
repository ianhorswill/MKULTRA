standard_concern(social_interaction).

on_event(social_interaction, SocialInteraction,
	 dialog(Speaker, Me, greeting),
	 begin_child_concern(SocialInteraction, conversation, Child,
			[ Child/partner/Speaker,
			  Child/heard_greeting,
			  Child/last_dialog:dialog(Speaker, $this, greeting) ])
	) :-
    Me is $game_object,
    \+(SocialInteraction/concerns/_/partner/Speaker).

on_event(social_interaction, SocialInteraction,
	 begin(dialog(_, Target, greeting)),
	 begin_child_concern(SocialInteraction, conversation, Child,
			[ Child/partner/Target,
			  Child/said_greeting,
			  Child/last_dialog:dialog(Me, Target, greeting) ])) :-
    \+(SocialInteraction/concerns/_/partner/Target),
    Me is $game_object.
