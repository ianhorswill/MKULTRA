%%%
%%%                  Noun Phrases
%%%

test_file(generate(np, _), "NL/np_tests").
test_file(complete(np, _), "NL/np_tests").
test_file(parse(np, _), "NL/np_tests").

:- indexical selectional_constraints=null.

impose_selectional_constraint(Var, Type) :-
   bind(selectional_constraints, [Var:Type | $selectional_constraints]).

selectional_constraint(Var, Type) :-
   memberchk(Var:Type, $selectional_constraints),
   !.
selectional_constraint(_, entity).

%:- randomizable np/7.

%% np(?Meaning, ?Case, Agreement, +GapIn, -GapOut)
%  Noun phrases

% Gaps
np((X^S)^S, _C, _Agreement, np(X), nogap) -->
   [ ].

% Pronouns
np(NP, Case, Agreement, Gap, Gap) -->
   pronoun(Case, Agreement,NP).

% Proper nouns
np((E^S)^S, _C, third:Number, Gap, Gap) -->
   { \+ bound_discourse_variable(E) },
   proper_noun(Number, E).

% PARSE/COMPLETE ONLY
% "a KIND" from unbound variables with declared types
np(LF, _, third:singular, Gap, Gap) -->
   { var(LF) }, 
   [a, Singular],
   { kind_noun(Kind, Singular, _),
     LF = ((X^S)^(S, is_a(X, Kind))) }.

% GENERATE ONLY
% "a KIND" from unbound variables with declared types
np((X^S)^S, _, third:singular, Gap, Gap) -->
   { var(X) },
   [a, Singular],
   { discourse_variable_type(X, Kind),
     kind_noun(Kind, Singular, _) }.

% PARSE ONLY
% "the NOUN"
np((X^S)^S, _C, third:singular, Gap, Gap) -->
   [ the, Noun ],
   { nonvar(Noun),
     noun(Noun, _, X^P),
     atomic(Noun),
     resolve_definite_description(X, P) }.

% GENERATE ONLY
% "the NOUN"
np((X^S)^S, _C, third:singular, Gap, Gap) -->
   { nonvar(X),
     % If it has a proper name or a bound variable, then don't use this rule.
     \+ proper_noun(_, X),
     is_a(X, Kind),
     leaf_kind(Kind),
     kind_noun(Kind, Singular, _) },
   [the, Singular].

% COMPLETE ONLY
% "the NOUN"
np((X^S)^S, _C, third:singular, Gap, Gap) -->
   % If we're generating (nonvar(X)) rather than completing (var(X)),
   % don't generate something that has a proper name.
   [the, SingularNoun],
   { var(X),
     input_from_player,
     \+ bound_discourse_variable(X),
     object_matching_selectional_constraint(X, SingularNoun) }.

object_matching_selectional_constraint(X, SingularNoun) :-
   selectional_constraint(X, ConstraintKind),
   is_a(X, ConstraintKind),
   noun_describing(X, SingularNoun).

noun_describing(X, SingularNoun) :-
   is_a(X, SpecificKind),
   kind_noun(SpecificKind, SingularNoun, _).

np((X^S)^S, _C, third:singular, Gap, Gap) -->
   [ the, N1, N2 ],
   { (nonvar(N1) ; nonvar(X)),
     noun([N1, N2], _, X^P),
     resolve_definite_description(X, P) }.

% GENERATE ONLY
% Fixed strings.
np((String^S)^S, _, _, Gap, Gap) -->
   {string(String)},
   [String].

% GENERATE ONLY
% Numbers.
np((Number^S)^S, _, _, Gap, Gap) -->
   {number(Number)},
   [Number].

resolve_definite_description(X, Constraint) :-
   nonvar(X),
   !,
   Constraint.
resolve_definite_description(Object, is_a(Object, Kind)) :-
   kind_of(Kind, room),
   !,
   is_a(Object, Kind).
resolve_definite_description(Object, Constraint) :-
   % This rule will fail in the test suite b/c the global environment has no gameobject.
   \+ running_tests,
   % Pick the nearest one, if it's something that nearest works on.
   nearest(Object, Constraint),
   !.
resolve_definite_description(_Object, Constraint) :-
   % Punt, and choose whatever Prolog gives us first.
   Constraint.