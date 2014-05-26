% To do:
% Vocative: "TOM, ..."

:- randomizable utterance//1, stock_phrase//1, sentence//1.

utterance(DialogAct) --> stock_phrase(DialogAct).
%utterance(DialogAct) --> sentence(DialogAct).
%utterance(DialogAct) --> answer_fragment(DialogAct).

stock_phrase(greet(_,_)) --> [X], { member(X, [hey, hello, hi]) }.
stock_phrase(greet(_,_)) --> [hi, there].

stock_phrase(apology(_,_)) --> [sorry].

stock_phrase(parting(_,_)) --> [X], { member(X, [bye, byebye, goodbye]) }.
stock_phrase(parting(_,_)) --> [see, you].
stock_phrase(parting(_,_)) --> [be, seeing, you].

