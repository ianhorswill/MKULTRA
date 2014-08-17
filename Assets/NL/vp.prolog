%%%                  Verb Phrases

%% aux_vp(LF, Person, Number, Tense, Progressive, Perfect)
%  Verb phrases, optionally augmented with auxilliaries and/or negative particle.

%test_aux_vp(LF) :-
%   aux_vp(LF, _, _, _, _, [can, halt], []).

:- randomizable aux_vp/7.
aux_vp(Subject^S, Polarity, Agreement, Tense, Aspect) -->
   aux_without_do_support(nogap, Polarity, Agreement, Tense, Aspect, Form, Predication^Modal),
   copula(Form, Tense, Agreement),
   opt_not_if_unbound(Polarity),
   copular_relation(Subject^Object^Predication), 
   np((Object^Modal)^S, object, _, nogap, nogap).

copula(base, _, _) -->
   [be].
copula(Form, Tense, Agreement) -->
   { Form \= base },
   aux_be(Tense, Agreement).

opt_not_if_unbound(Polarity) -->
   { var(Polarity) }, opt_not(Polarity).
opt_not_if_unbound(Polarity) -->
   { nonvar(Polarity) }, [ ].

:- randomizable copular_relation//1, copular_relation/2.
% copular_relation(Subject^Object^related(Subject, Relation, Object)) -->
%    [R1],
%    { copular_relation([R1], Relation) }.

copular_relation(Subject^Object^related(Subject, Relation, Object)) -->
   [R1, R2],
   { copular_relation([R1, R2], Relation) }.

copular_relation(Subject^Object^related(Subject, Relation, Object)) -->
   [R1, R2, R3],
   { copular_relation([R1, R2, R3], Relation) }.

aux_vp(VP, Polarity, Agreement, Tense, Aspect) --> 
   aux(nogap, Polarity, Agreement, Tense, Aspect, Form, M),
   vp(Form, M, VP, Tense, Agreement, nogap).

%% vp(?Form, ?Modal, ?Meaning, ?Tense, ?Agreement ?Gap)

:- randomizable vp/8.

%test_modal_vp(LF) :-
%   vp(_, X^can(X), LF, _, _, nogap, [halt], [ ]).

vp(Form, Predication^Modal, Subject^S, Tense, Agreement, Gap) -->
   { lf_predication(S, Predication) },
   iv(Form, Agreement, Subject^Predication, Tense, ForcePPs),
   opt_pp(ForcePPs, Predication, Gap, Modal, S).

vp(Form, Predication^Modal, Subject^S3, Tense, Agreement, GapInfo) -->
   { lf_predication(S3, Predication) },
   dtv(Form, Agreement,
       Subject^IndirectObject^DirectObject^Predication,
       Tense,
       ForcePPs), 
   np((IndirectObject^Modal)^S1, object, _, nogap, nogap),
   np((DirectObject^S1)^S2, object, _, GapInfo, GapOut),
   opt_pp(ForcePPs, Predication, GapOut, S2, S3).

vp(Form, Predication^Modal, Subject^S2, Tense, Agreement, GapInfo) -->
   { lf_predication(S2, Predication) },
   tv(Form, Agreement, Subject^Object^Predication, Tense, ForcePPs), 
   np((Object^Modal)^S1, object, _, GapInfo, GapOut),
   opt_pp(ForcePPs, Predication, GapOut, S1, S2).

%% lf_predication(?SentenceLF, ?Predication)

lf_predication(S, _) :-
   var(S), !.  % do nothing if we don't know what the sentence LF is.
lf_predication(_:S, P) :-
   !,
   lf_predication(S, P).
lf_predication(explanation(S,_), P) :-
   !,
   lf_predication(S, P).
lf_predication(not(S), P) :-
   !,
   lf_predication(S, P).
lf_predication(may(S), P) :-
   !,
   lf_predication(S, P).
lf_predication(should(S), P) :-
   !,
   lf_predication(S, P).
lf_predication(can(S), P) :-
   !,
   lf_predication(S, P).
lf_predication(must(S), P) :-
   !,
   lf_predication(S, P).
lf_predication(S, S).


%% lf_subject(?SentenceLF, ?Subject)

% Don't do anything if S is uninstantiated
lf_subject(S, _) :-
   var(S), !.
% If the LF is wrapped in modals or question markup, strip them away
lf_subject(_QuestionAnswerVar:QuestionConstraint, NP) :-
   !, lf_subject(QuestionConstraint, NP).
lf_subject(explanation(S, _Explanation), NP) :-
   !, lf_subject(S, NP).
%lf_subject(manner(S, _Manner), NP) :-
%   !, lf_subject(S, NP).
lf_subject(not(S), NP) :-
   !, lf_subject(S, NP).
lf_subject(can(S), NP) :-
   !, lf_subject(S, NP).
lf_subject(may(S), NP) :-
   !, lf_subject(S, NP).
lf_subject(should(S), NP) :-
   !, lf_subject(S, NP).
lf_subject(must(S), NP) :-
   !, lf_subject(S, NP).
% If we get this far, S should be the bare predication from the VP.
lf_subject(be(NP), NP) :-
   !.
lf_subject(related(NP, _, _), NP):-
   !.
lf_subject(S, NP) :-
   intransitive_verb(_, _, _, _, _, _, NP^S).
lf_subject(S, NP) :-
   transitive_verb(_, _, _, _, _, _, NP^_^S).
lf_subject(S, NP) :-
   ditransitive_verb(_, _, _, _, _, _, NP^_^_^S).



