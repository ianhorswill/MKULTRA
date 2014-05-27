% To do:
% Vocative: "TOM, ..."

:- randomizable utterance//1, stock_phrase//1, sentence//1.

utterance(DialogAct) --> stock_phrase(DialogAct).
%utterance(DialogAct) --> sentence(DialogAct).
%utterance(DialogAct) --> answer_fragment(DialogAct).

stock_phrase(greet($me, _)) --> [X], { member(X, [hey, hello, hi]) }.
stock_phrase(greet($me, _)) --> [hi, there].

stock_phrase(apology($me, _)) --> [sorry].

stock_phrase(parting($me, _)) --> [X], { member(X, [bye, byebye, goodbye]) }.
stock_phrase(parting($me, _)) --> [see, you].
stock_phrase(parting($me, _)) --> [be, seeing, you].

