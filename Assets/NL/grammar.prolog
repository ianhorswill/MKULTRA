% To do:
% Vocative: "TOM, ..."

:- indexical speaker=unknown_speaker, addressee=unknown_addressee, anaphore_context=[ ].

:- randomizable utterance//1, stock_phrase//1.

utterance(DialogAct) --> stock_phrase(DialogAct).
%utterance(question(Generator, Answer)) --> q(Generator, Answer).
utterance(assertion(LF, T, A)) --> s(LF, indicative, positive, T, A).
%utterance(DialogAct) --> sentence(DialogAct).
%utterance(DialogAct) --> answer_fragment(DialogAct).

%
% Stock phrases
%

stock_phrase(greet($speaker, _)) --> [X], { member(X, [hey, hello, hi]) }.
stock_phrase(greet($speaker, _)) --> [hi, there].

stock_phrase(apology($speaker, _)) --> [sorry].

stock_phrase(parting($speaker, _)) --> [X], { member(X, [bye, byebye, goodbye]) }.
stock_phrase(parting($speaker, _)) --> [see, you].
stock_phrase(parting($speaker, _)) --> [be, seeing, you].

