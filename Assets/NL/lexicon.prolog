
%% relpron( that ).
%% relpron( who  ).
%% relpron( whom ).

pronoun('I', subject, first, singular, $speaker).
pronoun(me, object, first, singular, $speaker).
pronoun(you, _, second, singular, $addressee).
pronoun(we, subject, first, plural, $dialog_group).
pronoun(us, object, first, plural, $dialog_group).

:- randomizable noun/3, proper_noun/2.

:- randomizable whpron/1.
whpron( who  ).
whpron( whom ).
whpron( what ).

:- randomizable det/2.
det( every, (X^S1)^(X^S2)^   all(X,S1,S2) ).
det( a,     (X^S1)^(X^S2)^exists(X,S1,S2)  ).
det( some,  (X^S1)^(X^S2)^exists(X,S1,S2)  ).

:- randomizable intransitive_verb/7.
:- randomizable transitive_verb/7.
:- randomizable ditransitive_verb/7.
