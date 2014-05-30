%
% Base grammar for sentences
% Based on the TALK grammar from Pereira and Sheiber.
%
 
/*=====================================================
                        Grammar

Nonterminal names:

        q        Question
        sinv     INVerted Sentence
        s        noninverted Sentence
        np       Noun Phrase
        vp       Verb Phrase
        iv       Intransitive Verb
        tv       Transitive Verb
	dv	 Ditransitive Verb
        aux      AUXiliary verb
        rov      subject-Object Raising Verb
        optrel   OPTional RELative clause
        relpron  RELative PRONoun
        whpron   WH PRONoun
        det      DETerminer
        n        Noun
        pn       Proper Noun

Typical order of and values for arguments:

   1. verb form:

      (main verbs)  finite, nonfinite, etc.
      (auxiliaries and raising verbs)  Form1-Form2 
          where Form1 is form of embedded VP
                Form2 is form of verb itself)

   2. FOL logical form

   3. gap information:  

      nogap or gap(Nonterm, Var)
          where Nonterm is nonterminal for gap
                    Var is the LF variable that
                           the filler will bind
=====================================================*/

%%%                    Questions

:- randomizable q//2.

q(S, X) --> 
   whpron, vp(finite, X^S, nogap).
q(S, X) --> 
   whpron, sinv(S, gap(np, X)).
q(S, yes) --> 
   sinv(S, nogap).
q(S, yes) -->
   copula(Person, Number), 
   np((X^S0)^S, subject, Person, Number, nogap), 
   np((X^true)^exists(X,S0,true), object, _, _, nogap).

%%%              Declarative Sentences

s(S, GapInfo) --> 
   np(VP^S, subject, Person, Number, nogap), 
   vp(finite, VP, Person, Number, GapInfo).

%%%               Inverted Sentences

sinv(S, GapInfo) --> 
   aux(finite/Form, VP1^VP2), 
   np(VP2^S, subject, Person, Number, nogap), 
   vp(Form, VP1, Person, Number, GapInfo).

%%%                  Noun Phrases

%% np(?Meaning, ?Case, ?Person, ?Number, ?Gap)

:- randomizable np//5.

np(NP, _C, third, Number, nogap) --> 
   det(N1^NP), n(Number, N1).
%   det(N2^NP), n(Number, N1), optrel(N1^N2).
np(NP, _C, third, Number, nogap) --> proper_noun(Number, NP).
np(NP, Case, Person, Number, nogap) --> pronoun(Case, Person, Number, NP).
np((X^S)^S, _C, _P, _Number, gap(np, X)) --> [].

%%%                  Verb Phrases

%% vp(?Form, ?Meaning, ?Person, ?Number, ?Gap)

:- randomizable vp//5.

vp(Form, X^S, Person, Number, GapInfo) -->
   tv(Form, Person, Number, X^VP), 
   np(VP^S, object, _, _, GapInfo).
vp(Form, VP, Person, Number, nogap) --> 
   iv(Form, Person, Number, VP).
vp(Form1, VP2, Person, Number, GapInfo) -->
   aux(Form1/Form2, VP1^VP2), 
   vp(Form2, VP1, Person, Number, GapInfo).
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


%%%                 Relative Clauses

%% :- randomizable optrel//1.

%% optrel(N^N) --> [].
%% optrel((X^S1)^(X^(S1,S2))) -->
%%    relpron, vp(finite,X^S2, nogap).
%% optrel((X^S1)^(X^(S1,S2))) -->
%%    relpron, s(S2, gap(np, X)).



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

pronoun(Case, Person, Number, (E^S)^S) --> [PN], {pronoun(PN, Case, Person, Number, E)}.

aux(Form, LF) --> [Aux], {aux(Aux, Form, LF)}.
%relpron --> [RP], {relpron(RP)}.
whpron --> [WH], {whpron(WH)}.

% Verb entry arguments:
%   1. base form
%   2. third person singular present tense form of the verb
%   3. logical form of the verb

:- randomizable iv//4.

iv(finite, third, singular, LF) --> [IV], {iv(_,  IV, LF)}.
iv(F,      P,     N,        LF) --> [IV], {iv(IV, _,  LF), dif(inflection(F,P,N), inflection(finite, third,singular)) }.

tv(finite, third, singular, LF) --> [TV], {tv(_,  TV, LF)}.
tv(F,      P,     N,        LF) --> [TV], {tv(TV, _,  LF), dif(inflection(F,P,N), inflection(finite, third,singular)) }.

%% rov(finite/Requires, third, singular, LF) --> [ROV], {raising_verb(_,   ROV, LF, Requires)}.
%% rov(_     /Requires, _,     _,        LF) --> [ROV], {raising_verb(ROV, _,   LF, Requires)}.

:- randomizable copula//2.

copula(first,  singular) --> [is].
copula(second, singular) --> [are].
copula(third,  singular) --> [is].
copula(_,      plural)   --> [are].

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

:- randomizable iv/3, tv/3.
iv( halt,      halts,      X^halt(X)         ).

tv( write,     writes,     X^Y^writes(X,Y)   ).
tv( meet,      meets,      X^Y^meets(X,Y)    ).
tv( concern,   concerns,   X^Y^concerns(X,Y) ).
tv( run,       runs,       X^Y^runs(X,Y)     ).

%% raising_verb( want,     wants,
%%      % semantics is partial execution of
%%      % NP ^ VP ^ Y ^ NP( X^want(Y,X,VP(X)) )
%%      ((X^want(Y,X,Comp))^S) ^ (X^Comp) ^ Y ^ S,
%%      % form of VP required:
%%      infinitival).

:- randomizable aux/3.
aux( to,   infinitival/nonfinite, VP^ VP       ).
aux( does, finite/nonfinite,      VP^ VP       ).
aux( did,  finite/nonfinite,      VP^ VP       ).
