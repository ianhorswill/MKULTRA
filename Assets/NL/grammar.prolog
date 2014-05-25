% To do:
% Vocative: "TOM, ..."

:- randomizable utterance//1, stock_phrase//1, sentence//1.

utterance(DialogAct) --> stock_phrase(DialogAct).
%utterance(DialogAct) --> sentence(DialogAct).
%utterance(DialogAct) --> answer_fragment(DialogAct).

stock_phrase(interruption) --> [excuse, me].
stock_phrase(ack(interruption)) --> [yes, '?'].

utterance(ack(greeting)) --> [ack], utterance(greeting).

stock_phrase(greeting) --> [X], { member(X, [hey, hello, hi]) }.
stock_phrase(greeting) --> [hi, there].

stock_phrase(apology) --> [sorry].
stock_phrase(ack(greeting)) --> [no, problem].
stock_phrase(ack(greeting)) --> [quite, alright].

stock_phrase(parting) --> [X], { member(X, [bye, byebye, goodbye]) }.
stock_phrase(parting) --> [see, you].
stock_phrase(parting) --> [be, seeing, you].
utterance(ack(parting)) --> utterance(parting).

