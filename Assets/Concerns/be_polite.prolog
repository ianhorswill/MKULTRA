standard_concern(be_polite).

score_action(greet(_, _), be_polite, _, 50).

on_event(enter_social_space(Character),
	 be_polite, C, 
	 assert(C/should_greet/Character)).

on_event(greet($me, Character),
	 be_polite, C,
	 ignore(retract(C/should_greet/Character))).

propose_action(greet($me, Character),
	       be_polite, C) :-
    C/should_greet/Character.
