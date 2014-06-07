
%% s(?S, ?Mood, ?Polarity, ?Tense, ?Aspect)

:- randomizable s//6.

s(S, indicative, positive, Tense, Aspect) -->
   np(VP^S, subject, Agreement, nogap),
   aux_vp(VP, Agreement, Tense, Aspect, nogap).
%s(S, imperative, positive, present, simple) -->
%   vp(finite, $addressee^S, second:singular).
% s(X:S, interrogative) --> 
%    whpron, vp(finite, X^S, nogap).
% s(X:S, interrogative) --> 
%    whpron, sinv(S, gap(np, X)).
% s(S, interrogative) --> 
%    sinv(S, nogap).
% s(S, interrogative) -->
%    copula(Person, Number), 
%    np((X^S0)^S, subject, Person, Number, nogap), 
%    np((X^true)^exists(X,S0,true), object, _, _, nogap).

%%%               Inverted Sentences

% sinv(S, GapInfo) --> 
%    aux(finite/Form, VP1^VP2), 
%    np(VP2^S, subject, Person, Number, nogap), 
%    vp(Form, VP1, Person, Number, GapInfo).

%%%                  Noun Phrases

%% np(?Meaning, ?Case, ?Person, ?Number, ?Gap)

:- randomizable np//4.

np(NP, _C, third:Number, nogap) --> 
   det(N1^NP), n(Number, N1).
np(NP, _C, third:Number, nogap) --> proper_noun(Number, NP).
np(NP, Case, Agreement, nogap) --> pronoun(Case, Agreement, NP).
np((X^S)^S, _C, _Agreement, np(X)) --> [].

%%%                  Verb Phrases

%% aux_vp(LF, Person, Number, Tense, Progressive, Perfect, Gap)

aux_vp(LF, Agreement, Tense, Aspect, Gap) -->
	aux(Agreement, Tense, Aspect, Form),
	vp(Form, LF, Tense, Agreement, Gap).

aux(_Agreement, present, simple, simple) --> [ ].
aux(Agreement, Tense, Aspect, Form) -->
	opt_will(Tense),
	aux_aspect(Tense, Aspect, Agreement, Form).

aux_aspect(_, simple, _, simple) --> [ ].

aux_aspect(Tense, progressive, Agreement, present_participle) -->
	aux_be(Tense, Agreement).
aux_aspect(Tense, Aspect, Agreement, Form) -->
	aux_have(Tense, Agreement),
	aux_perfect(Aspect, Agreement, Form).
aux_perfect(perfect, _Agreement, past_participle) -->
	[ ].
aux_perfect(perfect_progressive, Agreement, present_participle) -->
	aux_be(past, Agreement).

opt_will(future) --> [ will ].
opt_will(past, X, X).
opt_will(present, X, X).

aux_have(present, Agreement) -->
	[ have ],
	{ Agreement \= third:singular }.
aux_have(present, third:singular) -->
	[ has ].
aux_have(past, _Agreement) --> [had].
aux_have(future, _Agreement) --> [have].

aux_be(present, first:singular) -->
	[ am ].
aux_be(present, second:singular) -->
	[ are ].
aux_be(present, third:singular) -->
	[ is ].
aux_be(present, _:plural) -->
	[ are ].
aux_be(past, first:singular) -->
	[ was ].
aux_be(past, second:singular) -->
	[ were ].
aux_be(past, third:singular) -->
	[ was ].
aux_be(past, _:plural) -->
	[ were ].
aux_be(future, _Agreement) --> [be].

%% vp(?Form, ?Meaning, ?Tense, ?Agreement ?Gap)

% :- randomizable vp//4.

% vp(Form, X^S, Person, Number, GapInfo) -->
%    tv(Form, Person, Number, X^VP), 
%    np(VP^S, object, _, _, GapInfo).
vp(Form, VP, Tense, Agreement, nogap) --> 
    iv(Form, Agreement, VP, Tense).
% vp(Form1, VP2, Person, Number, GapInfo) -->
%    aux(Form1/Form2, VP1^VP2), 
%    vp(Form2, VP1, Person, Number, GapInfo).
%% vp(Form1, VP2, Person, Number, GapInfo) -->
%%    rov(Form1/Form2, Person, Number, NP^VP1^VP2), 
%%    np(NP, subject, Person, Number, GapInfo), 
%%    vp(Form2, VP1, Person, Number, nogap).
%% vp(Form2, VP2, Person, Number, GapInfo) -->
%%    rov(Form1/Form2, Person, Number, NP^VP1^VP2), 
%%    np(NP, subject, Person, Number, nogap), 
%%    vp(Form1, VP1, Person, Number, GapInfo).


%% This rule is responsible for creating a cyclic term when parsing 
%% sentences like "bertrand is bertrand" that will bomb the tree 
%% drawing routine. If you want to use this rule, you must not try 
%% to print the trees corresponding to sentences like that.

%% vp(finite, X^S, GapInfo) -->
%%   copula(Person, Number),
%%   np((X^P)^exists(X,S,P), object, Person, Number, GapInfo).


/*=====================================================
                      Dictionary
=====================================================*/

/*-----------------------------------------------------
                     Preterminals
-----------------------------------------------------*/

det(LF) --> [D], {det(D, LF)}.

:- randomizable n//2.
n(singular, LF)   --> [N], {n(N, _, LF)}.
n(plural, LF)   --> [N], {n(_, N, LF)}.

proper_noun(singular, (E^S)^S) --> [PN], {proper_noun(PN, E)}.

pronoun(Case, Person:Number, (E^S)^S) --> [PN], {pronoun(PN, Case, Person, Number, E)}.

%relpron --> [RP], {relpron(RP)}.
whpron --> [WH], {whpron(WH)}.

:- randomizable iv//4.

%                                                      Base TPS Past PastP PresP LF
iv(simple, third:singular, LF, present) --> [IV], { intransitive_verb(_,   IV, _,   _,    _,    LF) }.
iv(simple, Agreement,      LF, present) --> [IV], { intransitive_verb(IV,  _,  _,   _,    _,    LF),
						    Agreement \= third:singular }.
iv(simple, _Agreement,      LF, past)   -->  [IV], { intransitive_verb(_,  _,  IV,  _,    _,    LF) }.
iv(simple, _Agreement,      LF, future) -->  [IV], { intransitive_verb(IV, _,  _,   _,    _,    LF) }.
iv(past_participle, _Agreement,      LF, _Tense) -->  [IV], { intransitive_verb(_,  _,  _,   IV,   _,    LF) }.
iv(present_participle, _Agreement,   LF, _Tense) -->  [IV], { intransitive_verb(_,  _,  _,   _,    IV,   LF) }.


pronoun('I', subject, first, singular, $speaker).
pronoun(me, object, first, singular, $speaker).
pronoun(you, _, second, singular, $speaker).

/*-----------------------------------------------------
                     Lexical Items
-----------------------------------------------------*/

%% relpron( that ).
%% relpron( who  ).
%% relpron( whom ).

:- randomizable whpron/1.
whpron( who  ).
whpron( whom ).
whpron( what ).

:- randomizable det/2.
det( every, (X^S1)^(X^S2)^   all(X,S1,S2) ).
det( a,     (X^S1)^(X^S2)^exists(X,S1,S2)  ).
det( some,  (X^S1)^(X^S2)^exists(X,S1,S2)  ).

:- randomizable n/3.
n( author,     authors,     X^author(X)     ).
n( book,       books,       X^book(X)       ).
n( professor,  professors,  X^professor(X)  ).
n( program,    programs,    X^program(X)    ).
n( programmer, programmers, X^programmer(X) ).
n( student,    students,    X^student(X)    ).

:- randomizable pn/2.
proper_noun( begriffsschrift, begriffsschrift ).
proper_noun( bertrand,        bertrand        ).
proper_noun( bill,            bill            ).
proper_noun( gottlob,         gottlob         ).
proper_noun( lunar,           lunar           ).
proper_noun( principia,       principia       ).
proper_noun( shrdlu,          shrdlu          ).
proper_noun( terry,           terry           ).

:- randomizable intransitive_verb/6.
intransitive_verb(verb, verbs, verbed, verbed, verbing, X^verb(X)).
