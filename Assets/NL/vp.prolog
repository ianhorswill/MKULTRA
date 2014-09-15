%%%                  Verb Phrases

test_file(generate(vp, _), "NL/vp_tests").
test_file(complete(vp, _), "NL/vp_tests").
test_file(parse(vp, _), "NL/vp_tests").

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
