
%% relpron( that ).
%% relpron( who  ).
%% relpron( whom ).

pronoun_word('I', subject, first, singular, $speaker).
pronoun_word(me, object, first, singular, $speaker).
pronoun_word(you, _, second, singular, $addressee).
pronoun_word(we, subject, first, plural, $dialog_group).
pronoun_word(us, object, first, plural, $dialog_group).

:- randomizable noun/3, proper_noun/2.

:- randomizable whpron/2.
whpron( who, person  ).
%whpron( whom, person ).
whpron( what, entity ).

% :- randomizable det/2.
% det( every, (X^S1)^(X^S2)^   all(X,S1,S2) ).
% det( a,     (X^S1)^(X^S2)^exists(X,S1,S2)  ).
% det( some,  (X^S1)^(X^S2)^exists(X,S1,S2)  ).

:- randomizable intransitive_verb/7.
:- randomizable transitive_verb/7.
:- randomizable ditransitive_verb/7.

noun([living, room], [living, rooms], X^is_a(X,living_room)).

noun(action, actions, X^is_a(X, action)).
noun(assertion, assertions, X^is_a(X, assertion)).
noun(question, questions, X^is_a(X, question)).
