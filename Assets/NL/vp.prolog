%%%                  Verb Phrases

test_file(generate(vp, _), "NL/vp_tests").
test_file(complete(vp, _), "NL/vp_tests").
test_file(parse(vp, _), "NL/vp_tests").

%% aux_vp(LF, Person, Number, Tense, Progressive, Perfect)
%  Verb phrases, optionally augmented with auxilliaries and/or
%  negative particle.

:- randomizable aux_vp/7.

copula(past_participle, _, _) -->
   [been].
copula(present_participle, _, _) -->
   [being].
copula(Form, Tense, Agreement) -->
   { \+ memberchk(Form, [past_participle, present_participle]) },
   aux_be(Tense, Agreement).

aux_vp(VP, Polarity, Agreement, Tense, Aspect) --> 
   aux(nogap, Polarity, Agreement, Tense, Aspect, Form, M),
   vp(Form, M, VP, Tense, Agreement, nogap).

%% vp(?Form, ?Modal, ?Meaning, ?Tense, ?Agreement ?Gap)

:- randomizable vp/8.

%test_modal_vp(LF) :-
%   vp(_, X^can(X), LF, _, _, nogap, [halt], [ ]).
vp(Form, Predication^Modal, Subject^S, Tense, Agreement, Gap) -->
   { lf_core_predicate(S, Predication) },
   iv(Form, Agreement, Subject^Predication, Tense, ForcePPs),
   opt_pp(ForcePPs, Predication, Gap, Modal, S).

vp(Form, Predication^Modal, Subject^S3, Tense, Agreement, GapInfo) -->
   { lf_core_predicate(S3, Predication) },
   dtv(Form, Agreement,
       Subject^IndirectObject^DirectObject^Predication,
       Tense,
       ForcePPs), 
   np((IndirectObject^Modal)^S1, object, _, nogap, nogap),
   np((DirectObject^S1)^S2, object, _, GapInfo, GapOut),
   opt_pp(ForcePPs, Predication, GapOut, S2, S3).

vp(Form, Predication^Modal, Subject^S2, Tense, Agreement, GapInfo) -->
   { lf_core_predicate(S2, Predication) },
   tv(Form, Agreement, Subject^Object^Predication, Tense, ForcePPs), 
   np((Object^Modal)^S1, object, _, GapInfo, GapOut),
   opt_pp(ForcePPs, Predication, GapOut, S1, S2).

%% Turn phrasal verbs
%% Someday this should be data driven
vp(_Form, Predicate^Modal, Subject^S, Tense, Agreement, GapInfo) -->
   turn_verb(Agreement, Tense),
   [TurnAdverb],
   { turn_phrasal_verb(TurnAdverb, Subject, Object, Predicate) },
   np((Object^Modal)^S, object, _, GapInfo, nogap).
vp(_Form, Predicate^Modal, Subject^S, Tense, Agreement, GapInfo) -->
   turn_verb(Agreement, Tense),
   np((Object^Modal)^S, object, _, GapInfo, nogap),
   [TurnAdverb],
   { turn_phrasal_verb(TurnAdverb, Subject, Object, Predicate) }.

turn_verb(_, present) --> [turn].
turn_verb(_, past) --> [turned].

turn_phrasal_verb(on, S, O, turn_on(S, O)).
turn_phrasal_verb(off, S, O, turn_off(S, O)).

