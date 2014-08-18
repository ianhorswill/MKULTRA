% To do:
% Vocative: "TOM, ..."

:- indexical anaphore_context=[ ].

:- randomizable utterance//1, stock_phrase//1.

utterance(DialogAct) --> stock_phrase(DialogAct).
utterance(question($speaker, $addressee, LF, T, A)) -->
   sentence(LF, interrogative, affirmative, T, A).
utterance(assertion($speaker, $addressee, LF, T, A)) --> sentence(LF, indicative, affirmative, T, A).
utterance(assertion($speaker, $addressee, not(LF), T, A)) --> sentence(LF, indicative, negative, T, A).
utterance(command($speaker, $addressee, LF)) --> sentence(LF, imperative, affirmative, _, _).
utterance(injunction($speaker, $addressee, LF)) --> sentence(LF, imperative, negative, _, _).
utterance(agree($speaker, $addressee, _LF)) --> [ yes ].
utterance(disagree($speaker, $addressee, _LF)) --> [ no ].

%
% Stock phrases
%

stock_phrase(do_not_understand($me, _)) --> [ huh, '?'].
stock_phrase(prompt_player($me, $me)) --> [type, something].

stock_phrase(greet($speaker, _)) --> [X], { member(X, [hey, hello, hi]) }.
stock_phrase(greet($speaker, _)) --> [hi, there].

stock_phrase(apology($speaker, _)) --> [sorry].

stock_phrase(parting($speaker, _)) --> [X], { member(X, [bye, byebye, goodbye]) }.
stock_phrase(parting($speaker, _)) --> [see, you].
stock_phrase(parting($speaker, _)) --> [be, seeing, you].

%
% Increments produced by the discourse generator
%

utterance(discourse_increment(Speaker, Addressee, Fragments)) -->
   { generating_nl,               % Only valid for character output, not player input.
     bind(speaker, Speaker),
     bind(addressee, Addressee) },
   discourse_fragments(Fragments).

discourse_fragments([]) -->
   [ ].
discourse_fragments([F | Fs]) -->
   discourse_fragment(F),
   discourse_fragments(Fs).

discourse_fragment(s(X)) -->
   {!}, sentence(X, indicative, affirmative, present, simple).

discourse_fragment(np(X)) -->
   {kind(X), !}, [a, X].

discourse_fragment(np(X)) -->
   {!}, np((X^S)^S, subject, third:singular, nogap, nogap).

discourse_fragment(X) -->
   { string(X), ! },
   [ X ].

%
% Interface to action system
%

action_functor(discourse_increment, 5).

make_all_utterances_actions :-
   forall(( clause(utterance(A, _, _), _),
	    nonvar(A) ),
	  assert_action_functor(A)),
   forall(clause(stock_phrase(A, _, _), _),
	  assert_action_functor(A)).

assert_action_functor(Structure) :-
   functor(Structure, Functor, Arity),
   ( action_functor(Functor, Arity) -> true
     ;
     assert(action_functor(Functor, Arity)) ).

:- make_all_utterances_actions.

:- public make_all_utterances_actions/0.