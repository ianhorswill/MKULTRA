%%%
%%%                  Noun Phrases
%%%

%% np(?Meaning, ?Case, Agreement, +GapIn, -GapOut)
%  Noun phrases

%np(NP, _C, third:Number, nogap) --> 
%   det(N1^NP), n(Number, N1).

% np((X^_)^_, _, _, _, _, [Y | _], _) :-
%    % Catch cases where we don't know the LF or the words.
%    var(X), var(Y), !, fail.
np((X^S)^S, _C, _A, Gap, Gap) -->
   [ the, Noun ],
   { noun(Noun, _, X^P),
     nearest(X, P) }.
np(NP, Case, Agreement, Gap, Gap) --> pronoun(Case, Agreement, NP).
np(NP, _C, third:Number, Gap, Gap) --> proper_noun(Number, NP).
np((X^_)^_, _C, _Agreement, np(X), nogap) --> [].
np((String^_)^_, _, _, Gap, Gap) --> {string(String)}, [String].

