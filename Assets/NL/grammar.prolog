% To do:
% Vocative: "TOM, ..."

:- indexical speaker=unknown_speaker, addressee=unknown_addressee, dialog_group=unknown_dialog_group.
:- indexical anaphore_context=[ ].

:- randomizable utterance//1, stock_phrase//1.

utterance(DialogAct) --> stock_phrase(DialogAct).
utterance(question($speaker, $addressee, LF, T, A)) -->
   sentence(LF, interrogative, affirmative, T, A).
utterance(assertion($speaker, $addressee, LF, T, A)) --> sentence(LF, indicative, affirmative, T, A).
utterance(assertion($speaker, $addressee, not(LF), T, A)) --> sentence(LF, indicative, negative, T, A).
utterance(command($speaker, $addressee, LF)) --> sentence(LF, imperative, affirmative, _, _).
utterance(injunction($speaker, $addressee, LF)) --> sentence(LF, imperative, negative, _, _).

%
% Stock phrases
%

stock_phrase(prompt_player($me, $me)) --> [type, something].

stock_phrase(greet($speaker, _)) --> [X], { member(X, [hey, hello, hi]) }.
stock_phrase(greet($speaker, _)) --> [hi, there].

stock_phrase(apology($speaker, _)) --> [sorry].

stock_phrase(parting($speaker, _)) --> [X], { member(X, [bye, byebye, goodbye]) }.
stock_phrase(parting($speaker, _)) --> [see, you].
stock_phrase(parting($speaker, _)) --> [be, seeing, you].

