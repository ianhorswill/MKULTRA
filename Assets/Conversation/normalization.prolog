normalize_dialog_act(Act, Normalized) :-
   da_normal_form(Act, Reduced),
   !,
   normalize_dialog_act(Reduced, Normalized).
normalize_dialog_act(Act, Act).

% Indirect request - "can you hand me that screwdriver?"
da_normal_form(question(Speaker, Addressee, can(Command), present, simple),
	       command(Speaker, Addressee, Command)).
% Indirect request - "I want you to hand me the screwdriver"
da_normal_form(assertion(Speaker, Addressee, want(Speaker, Command), present, simple),
	       command(Speaker, Addressee, Command)) :-
   agent(Command, Addressee).

da_normal_form(command(Speaker, Addressee, Command),
	       question(Speaker, Addressee, Question, present, simple)) :-
   imperative_indirect_question(Speaker, Addressee, Command, Question).

imperative_indirect_question(S, A, tell_value(A, S, Question), Question).

da_normal_form(assertion(Speaker, Addressee, Assertion, _, _),
	       question(Speaker, Addressee, Question, present, simple)) :-
   declarative_indirect_question(Speaker, Addressee, Assertion, Question).

declarative_indirect_question(S, _, want(S, knows_value(S, Question)), Question).
