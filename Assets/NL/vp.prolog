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
copula(base, _, _) --> [be].
copula(Form, Tense, Agreement) -->
   { \+ memberchk(Form, [base, past_participle, present_participle]) },
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

%%%
%%% Infinitival VPs
%%%

infinitival_vp(LF) -->
   [to],
   vp(base, S^S, LF, present, _Agreement, nogap).

%%%
%%% Special case verbs
%%%

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

:- register_lexical_item(turn),
   forall(turn_phrasal_verb(Word, _, _, _),
	  register_lexical_item(Word)).

%% modal verbs

vp(_, Predicate^Modal, Subject^Modal, Tense, Agreement, nogap) -->
   not_generating_or_completing,
   modal_verb(Tense, Agreement, Subject^Complement^Predicate),
   infinitival_clause(Subject, Complement).

modal_verb(present, third:singular, S^C^want(S, C)) --> [wants].
modal_verb(present, Agreement, S^C^want(S, C)) -->
   [want],
   { dif(Agreement, third:singular) }.
modal_verb(past, _Agreement, S^C^want(S, C)) -->
   [wanted].

modal_verb(present, third:singular, S^C^need(S, C)) --> [needs].
modal_verb(present, Agreement, S^C^need(S, C)) -->
   [need],
   { dif(Agreement, third:singular) }.
modal_verb(past, _Agreement, S^C^need(S, C)) -->
   [needed].

:- forall(modal_verb(_, _, _, Phrase, []),
	  register_lexical_items(Phrase)).

%% Other verbs with clausal complements

vp(_, TransformedPredicate^Modal, Subject^Modal, Tense, Agreement, nogap) -->
   not_generating_or_completing,
   verb_with_clausal_complement(Tense, Agreement, Complementizer, Subject^Complement^Predicate),
   complementizer(Complementizer, Predicate^TransformedPredicate),
   finite_clause(Complement).

%% complementizer(Type, Transformer)
%  Matches a complementizer (that, if, whether, null), and gives its semantics for transforming the
%  verb's normal LF into the final LF.  Used to allow if and whether to change know into know_if.
complementizer(if, know(X,Y)^know_if(X,Y)) --> [whether].
complementizer(if, know(X,Y)^know_if(X,Y)) --> [if].
complementizer(that, X^X) --> [that].
complementizer(that, X^X) --> [].

verb_with_clausal_complement(present, third:single, that, Subject^Complement^believe(Subject, Complement)) -->
   [believes].
verb_with_clausal_complement(past, _, that, Subject^Complement^believe(Subject, Complement)) -->
   [believed].
verb_with_clausal_complement(present, Agreement, that, Subject^Complement^believe(Subject, Complement)) -->
   [believe],
   { dif(Agreement, third:single) }.

verb_with_clausal_complement(present, third:single, _, Subject^Complement^know(Subject, Complement)) -->
   [knows].
verb_with_clausal_complement(past, _, _, Subject^Complement^know(Subject, Complement)) -->
   [knew].
verb_with_clausal_complement(present, Agreement, _, Subject^Complement^know(Subject, Complement)) -->
   [know],
   { dif(Agreement, third:single) }.

:- forall(verb_with_clausal_complement(_, _, _, _, Phrase, []),
	  register_lexical_items(Phrase)).



