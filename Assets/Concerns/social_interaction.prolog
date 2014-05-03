on_event(social_interaction, This, dialog(Speaker, $this, greeting)) :-
    begin_child_concern(This, conversation, Child,
			[ interlocutor/Speaker,
			  last_dialog:dialog(Speaker, $this, greeting) ]).

on_event(social_interaction, This, dialog($this, Target, greeting)) :-
    begin_child_concern(This, conversation, Child,
			[ interlocutor/Target,
			  last_dialog:dialog($this, Target, greeting) ]).

