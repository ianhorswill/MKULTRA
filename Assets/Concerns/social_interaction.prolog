standard_concern(social_interaction).

on_event(social_interaction, SocialInteraction,
	 dialog(Speaker, Me, greeting)) :-
    Me is $game_object,
    \+(SocialInteraction/concerns/_/interlocutor/Speaker),
    begin_child_concern(SocialInteraction, conversation, Child,
			[ Child/interlocutor/Speaker,
			  Child/last_dialog:dialog(Speaker, $this, greeting) ]).

on_event(social_interaction, SocialInteraction,
	 begin(dialog(_, Target, greeting))) :-
    \+(SocialInteraction/concerns/_/interlocutor/Target),
    Me is $game_object,
    begin_child_concern(SocialInteraction, conversation, Child,
			[ Child/interlocutor/Target,
			  Child/last_dialog:dialog(Me, Target, greeting) ]).
