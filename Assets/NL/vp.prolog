%%%                  Verb Phrases

%% aux_vp(LF, Person, Number, Tense, Progressive, Perfect)
%  Verb phrases, optionally augmented with auxilliaries and/or negative particle.

%test_aux_vp(LF) :-
%   aux_vp(LF, _, _, _, _, [can, halt], []).

aux_vp(VP, Polarity, Agreement, Tense, Aspect) --> 
   aux(nogap, Polarity, Agreement, Tense, Aspect, Form, M),
   vp(Form, M, VP, Tense, Agreement, nogap).

%% vp(?Form, ?Modal, ?Meaning, ?Tense, ?Agreement ?Gap)

:- randomizable vp//6.

%test_modal_vp(LF) :-
%   vp(_, X^can(X), LF, _, _, nogap, [halt], [ ]).

vp(Form, Predication^S1, Subject^S2, Tense, Agreement, Gap) --> 
   iv(Form, Agreement, Subject^Predication, Tense),
   opt_pp(Predication, Gap, S1, S2).

vp(Form, Predication^Modal, Subject^S3, Tense, Agreement, GapInfo) -->
   dtv(Form, Agreement,
       Subject^IndirectObject^DirectObject^Predication,
       Tense), 
   np((IndirectObject^Modal)^S1, object, _, nogap, nogap),
   np((DirectObject^S1)^S2, object, _, GapInfo, GapOut),
   opt_pp(Predication, GapOut, S2, S3).

vp(Form, Predication^Modal, Subject^S2, Tense, Agreement, GapInfo) -->
   tv(Form, Agreement, Subject^Object^Predication, Tense), 
   np((Object^Modal)^S1, object, _, GapInfo, GapOut),
   opt_pp(Predication, GapOut, S1, S2).

%% analyze_lf(?SentenceLF, ?VP_LF)
%  Fill in VP_LF from SentenceLF, if SentenceLF is instantiated
%  This is needed inside the productions for the S nonterminal
%  because when generating a sentence, the LF for the subject
%  of the sentence would otherwise not get bound until the VP
%  was parsed (because the VP determines which part of the LF
%  is the LF of the subject.  That causes the NP productions to
%  exhaustively generate every possible noun phrase to see if
%  it has the LF needed by the VP.
%
%  So we handle this by detecting the case where the LF of the
%  sentence is already instantiated (i.e. where we're generating)
%  and searching down inside to bind the LF of the verb phrase
%  in paricular, so that can be passed instantiated to the NP
%  productions, allowing them to figure out what their LFs are.

% Don't do anything if S is uninstantiated
analyze_lf(S, _VP) :-
   var(S), !.
% If the LF is wrapped in modals or question markup, strip them away
analyze_lf(_QuestionAnswerVar:QuestionConstraint, VP) :-
   !, analyze_lf(QuestionConstraint, VP).
analyze_lf(explanation(S, _Explanation), VP) :-
   !, analyze_lf(S, VP).
%analyze_lf(manner(S, _Manner), VP) :-
%   !, analyze_lf(S, VP).
analyze_lf(not(S), VP) :-
   !, analyze_lf(S, VP).
analyze_lf(can(S), can(VP)) :-
   !, analyze_lf(S, VP).
analyze_lf(may(S), VP) :-
   !, analyze_lf(S, VP).
analyze_lf(should(S), VP) :-
   !, analyze_lf(S, VP).
analyze_lf(must(S), VP) :-
   !, analyze_lf(S, VP).
% If we get this far, S should be the bare predication from the VP.
analyze_lf(be(NP), NP^be(NP)) :-
   !.
analyze_lf(S, NP^S) :-
   intransitive_verb(_, _, _, _, _, NP^S).
analyze_lf(S, NP^S) :-
   transitive_verb(_, _, _, _, _, NP^_^S).
analyze_lf(S, NP^S) :-
   ditransitive_verb(_, _, _, _, _, NP^_^_^S).



