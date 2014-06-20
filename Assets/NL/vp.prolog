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

vp(Form, Predication^Modal, Subject^S2, Tense, Agreement, GapInfo) -->
   tv(Form, Agreement, Subject^Object^Predication, Tense), 
   np((Object^Modal)^S1, object, _, GapInfo, GapOut),
   opt_pp(Predication, GapOut, S1, S2).

vp(Form, Predication^Modal, Subject^S3, Tense, Agreement, GapInfo) -->
   dtv(Form, Agreement,
       Subject^IndirectObject^DirectObject^Predication,
       Tense), 
   np((IndirectObject^Modal)^S1, object, _, nogap, nogap),
   np((DirectObject^S1)^S2, object, _, GapInfo, GapOut),
   opt_pp(Predication, GapOut, S2, S3).

