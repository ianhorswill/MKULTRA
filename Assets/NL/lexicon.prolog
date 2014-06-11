
%% relpron( that ).
%% relpron( who  ).
%% relpron( whom ).

pronoun('I', subject, first, singular, $speaker).
pronoun(me, object, first, singular, $speaker).
pronoun(you, _, second, singular, $speaker).

:- randomizable whpron/1.
whpron( who  ).
whpron( whom ).
whpron( what ).

:- randomizable det/2.
det( every, (X^S1)^(X^S2)^   all(X,S1,S2) ).
det( a,     (X^S1)^(X^S2)^exists(X,S1,S2)  ).
det( some,  (X^S1)^(X^S2)^exists(X,S1,S2)  ).

:- randomizable n/3.
noun( author,     authors,     X^author(X)     ).
noun( book,       books,       X^book(X)       ).
noun( professor,  professors,  X^professor(X)  ).
noun( program,    programs,    X^program(X)    ).
noun( programmer, programmers, X^programmer(X) ).
noun( student,    students,    X^student(X)    ).

:- randomizable proper_noun/2.
proper_noun( begriffsschrift, begriffsschrift ).
proper_noun( bertrand,        bertrand        ).
proper_noun( bill,            bill            ).
proper_noun( gottlob,         gottlob         ).
proper_noun( lunar,           lunar           ).
proper_noun( principia,       principia       ).
proper_noun( shrdlu,          shrdlu          ).
proper_noun( terry,           terry           ).

proper_noun(Name, WorldObject) :-
	nonvar(Name),
	String is Name.'Name',
	world_object(WorldObject),
	String is WorldObject.name .
% proper_noun(Name, WorldObject) :-
% 	var(Name),
% 	world_object(WorldObject),
% 	String is WorldObject.name,
% 	Name is $'Symbol'.'Intern'(String).

:- randomizable intransitive_verb/6.
:- randomizable transitive_verb/6.