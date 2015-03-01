%%
%% Responding to assertions
%%

strategy(respond_to_dialog_act(assertion(Speaker,_, LF, Tense, Aspect)),
	 respond_to_assertion(Speaker, Modalized, Truth)) :-
   modalized(LF, Tense, Aspect, Modalized),
   admitted_truth_value(Speaker, Modalized, Truth).

strategy(respond_to_assertion(_Speaker, _ModalLF, true),
	 say_string("Yes, I know.")).
strategy(respond_to_assertion(_Speaker, _ModalLF, false),
	 say_string("I don't think so.")).
strategy(respond_to_assertion(Speaker, ModalLF, unknown),
	 (say_string(Response), assert(/hearsay/Speaker/ModalLF))) :-
   heard_hearsay(ModalLF) -> Response="I've head that." ; Response="Really?".

heard_hearsay(ModalLF) :-
   /hearsay/_/Assertion, Assertion=ModalLF.
