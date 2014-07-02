%%
%% Prepositional phrases
%%
%% VPs produce predications as their meanings (e.g. go(Agent, Destination)).
%% Syntactically, go is non-transitive, so the predication of the phrase "I go"
%% go($me, _Dest), meaning the destination slot is left blank on exit from
%% the parsing of the verb.  PPs can be used to fill these slots in.  The parser
%% does not support fancier uses of PPs, since logical forms are restricted to
%% look like: quantifiers(modal(predication(args...))).
%%

%% opt_pp(Predication, +Gap, SentenceLFIn, SentenceLFOut)
%  Fills in slots of Predication, specified by PPs, and wrapping SentenceLFIn
%  in any further quantifiers from the NPs of the PPs, to produce SentenceLFOut

opt_pp(Predication, Gap, SIn, SOut) -->
   { generating_nl, ! },
   generator_pp(Predication, Gap, SIn, SOut).

opt_pp(Predication, Gap, SIn, SOut) -->
   parser_opt_pp(Predication, Gap, SIn, SOut).

%%% FINISH THIS
generator_pp(_Predication, nogap, S, S) --> [ ].

:- randomizable parser_opt_pp//3.

parser_opt_pp(_, nogap, S, S) --> [ ].
parser_opt_pp(Predication, Gap, S1, S3) -->
   [ Preposition ],
   { preposition(Preposition),
     prepositional_slot(Preposition, X, Predication) },
   np((X^S1)^S2, object, _, Gap, nogap),
   opt_pp(Predication, nogap, S2, S3).

%% preposition(?Word)
%  Word is a preposition
:- randomizable preposition/1.
preposition(from).
preposition(to).
preposition(about).
preposition(with).
preposition(on).
preposition(in).

%% prepositional_slot(?Preposition, ?Referrent, ?Predication
%  True when the slot of Predication corresponding to Preposition
%  has the value Referrent.
:- randomizable prepositional_slot/3.
