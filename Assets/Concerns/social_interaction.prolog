standard_concern(social_interaction).

on_event(greet(Speaker, $me),
	 social_interaction,
	 SocialInteraction,
	 launch_conversation(SocialInteraction,
			     Speaker,
			     greet(Speaker, $me))
	) :-
   Speaker \= player,
    \+(SocialInteraction/concerns/_/partner/Speaker).

on_event(greet($me, Target),
	 social_interaction,
	 SocialInteraction,
	 launch_conversation(SocialInteraction,
			     Target,
			     greet($me, Target))
	) :-
   Target \= player,
   \+(SocialInteraction/concerns/_/partner/Target).


