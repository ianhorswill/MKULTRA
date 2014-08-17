%%%
%%%                  Noun Phrases
%%%

%:- randomizable np/7.

%% np(?Meaning, ?Case, Agreement, +GapIn, -GapOut)
%  Noun phrases

%np(NP, _C, third:Number, nogap) --> 
%   det(N1^NP), n(Number, N1).

% np((X^_)^_, _, _, _, _, [Y | _], _) :-
%    % Catch cases where we don't know the LF or the words.
%    var(X), var(Y), !, fail.
np((X^S)^S, _, third:singular, Gap, Gap) -->
   { var(X),
     discourse_variable_type(X, Kind),
     noun(Kind, _, _) },
   [a, Kind].
np((X^S)^S, _C, third:singular, Gap, Gap) -->
   [ Det, Noun ],
   { memberchk(Det, [the, a]),
     noun(Noun, _, X^P),
     atomic(Noun),
     resolve_definite_description(X, P) }.
np((X^S)^S, _C, third:singular, Gap, Gap) -->
   [ the, N1, N2 ],
   { noun([N1, N2], _, X^P),
     resolve_definite_description(X, P) }.
np(NP, Case, Agreement, Gap, Gap) -->
   pronoun(Case, Agreement, NP).
np(NP, _C, third:Number, Gap, Gap) -->
   proper_noun(Number, NP).
np((X^S)^S, _C, _Agreement, np(X), nogap) -->
   [].
np((String^S)^S, _, _, Gap, Gap) -->
   {string(String)},
   [String].
np((Number^S)^S, _, _, Gap, Gap) -->
   {number(Number)},
   [Number].

resolve_definite_description(Object, is_a(Object, Kind)) :-
   kind_of(Kind, room),
   !,
   is_a(Object, Kind).
resolve_definite_description(Object, Constraint) :-
   % Pick the nearest one, if it's something that nearest works on.
   nearest(Object, Constraint),
   !.
resolve_definite_description(_Object, Constraint) :-
   % Punt, and choose whatever Prolog gives us first.
   Constraint.