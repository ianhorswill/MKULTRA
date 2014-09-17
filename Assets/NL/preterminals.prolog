%:- public det/3.

%det(LF) --> [D], {det(D, LF)}.

:- randomizable proper_noun/2, proper_noun/4.
proper_noun(singular, (E^S)^S) -->
   [PN],
   { \+ bound_discourse_variable(E),
     proper_noun(PN, E),
     atomic(PN) }.

proper_noun(singular, (E^S)^S) -->
   [PN1, PN2],
   { \+ bound_discourse_variable(E),
     proper_noun([PN1, PN2], E)}.

pronoun(Case, Person:Number, (E^S)^S) -->
   [PN],
   { \+ bound_discourse_variable(E),
     pronoun_word(PN, Case, Person, Number, E) }.

%relpron --> [RP], {relpron(RP)}.
whpron(Kind) -->
   { Kind \== person },
   [what, Plural],
   { kind_noun(Kind, _, Plural) }.

whpron(Kind) --> [WH], {whpron(WH, Kind)}.

%%
%% Verb conjugations
%%

:- randomizable iv//5.
%                                                      Base TPS Past PastP PresP LF
iv(simple, third:singular, LF, present, ForcePPs) -->
   [IV],
   { intransitive_verb(_,   IV, _,   _,    _,    ForcePPs, LF) }.
iv(simple, Agreement,      LF, present, ForcePPs) -->
   [IV],
   { intransitive_verb(IV,  _,  _,   _,    _,    ForcePPs, LF),
     Agreement \= third:singular }.
iv(simple, _Agreement,      LF, past, ForcePPs)   -->
   [IV],
   { intransitive_verb(_,  _,  IV,  _,    _,    ForcePPs, LF) }.
iv(simple, _Agreement,      LF, future, ForcePPs) -->
   [IV],
   { intransitive_verb(IV, _,  _,   _,    _,    ForcePPs, LF) }.
% Used only in the construction X does not BASEFORM.
iv(base, _Agreement,      LF, present, ForcePPs) -->
   [IV],
   { intransitive_verb(IV, _,  _,   _,    _,    ForcePPs, LF) }.
iv(base, _Agreement,      LF, past, ForcePPs) -->
   [IV],
   { intransitive_verb(IV, _,  _,   _,    _,    ForcePPs, LF) }.
iv(past_participle, _Agreement,      LF, _Tense, ForcePPs) -->
   [IV],
   { intransitive_verb(_,  _,  _,   IV,   _,    ForcePPs, LF) }.
iv(present_participle, _Agreement,   LF, _Tense, ForcePPs) -->
   [IV],
   { intransitive_verb(_,  _,  _,   _,    IV,   ForcePPs, LF) }.

end_csv_loading(intransitive_verb) :-
   check_lexicon_typing(LF^intransitive_verb(_, _, _, _, _, _, LF)).

					
:- randomizable tv//5.
%                                                      Base TPS Past PastP PresP LF
tv(simple, third:singular, LF, present, ForcePPs) -->
   [TV],
   { transitive_verb(_,   TV, _,   _,    _,    ForcePPs, LF) }.
tv(simple, Agreement,      LF, present, ForcePPs) -->
   [TV],
   { transitive_verb(TV,  _,  _,   _,    _,    ForcePPs, LF),
     Agreement \= third:singular }.
tv(simple, _Agreement,      LF, past, ForcePPs)   -->
   [TV],
   { transitive_verb(_,  _,  TV,  _,    _,    ForcePPs, LF) }.
tv(simple, _Agreement,      LF, future, ForcePPs) -->
   [TV],
   { transitive_verb(TV, _,  _,   _,    _,    ForcePPs, LF) }.
% Used only in the construction X does not BASEFORM.
tv(base, _Agreement,      LF, present, ForcePPs) -->
   [TV],
   { transitive_verb(TV, _,  _,   _,    _,    ForcePPs, LF) }.
tv(base, _Agreement,      LF, past, ForcePPs) -->
   [TV],
   { transitive_verb(TV, _,  _,   _,    _,    ForcePPs, LF) }.
tv(past_participle, _Agreement,      LF, _Tense, ForcePPs) -->
   [TV],
   { transitive_verb(_,  _,  _,   TV,   _,    ForcePPs, LF) }.
tv(present_participle, _Agreement,   LF, _Tense, ForcePPs) -->
   [TV],
   { transitive_verb(_,  _,  _,   _,    TV,   ForcePPs, LF) }.

end_csv_loading(transitive_verb) :-
   check_lexicon_typing(LF^transitive_verb(_, _, _, _, _, _, LF)).


:- randomizable dtv//5.
%                                                      Base TPS Past PastP PresP LF
dtv(simple, third:singular, LF, present, ForcePPs) -->
   [DTV],
   { ditransitive_verb(_,   DTV, _,   _,    _,    ForcePPs, LF) }.
dtv(simple, Agreement,      LF, present, ForcePPs) -->
   [DTV],
   { ditransitive_verb(DTV,  _,  _,   _,    _,    ForcePPs, LF),
     Agreement \= third:singular }.
dtv(simple, _Agreement,      LF, past, ForcePPs)   -->
   [DTV],
   { ditransitive_verb(_,  _,  DTV,  _,    _,    ForcePPs, LF) }.
dtv(simple, _Agreement,      LF, future, ForcePPs) -->
   [DTV],
   { ditransitive_verb(DTV, _,  _,   _,    _,    ForcePPs, LF) }.
% Used only in the construction X does not BASEFORM.
dtv(base, _Agreement,      LF, present, ForcePPs) -->
   [DTV],
   { ditransitive_verb(DTV, _,  _,   _,    _,    ForcePPs, LF) }.
dtv(base, _Agreement,      LF, past, ForcePPs) -->
   [DTV],
   { ditransitive_verb(DTV, _,  _,   _,    _,    ForcePPs, LF) }.
dtv(past_participle, _Agreement,      LF, _Tense, ForcePPs) -->
   [DTV],
   { ditransitive_verb(_,  _,  _,   DTV,   _,    ForcePPs, LF) }.
dtv(present_participle, _Agreement,   LF, _Tense, ForcePPs) -->
   [DTV],
   { ditransitive_verb(_,  _,  _,   _,    DTV,   ForcePPs, LF) }.

end_csv_loading(ditransitive_verb) :-
   check_lexicon_typing(LF^ditransitive_verb(_, _, _, _, _, _, LF)).

check_lexicon_typing(LF^Generator) :-
   forall(Generator,
	  check_lexical_entry_type(LF)).

check_lexical_entry_type(_Arg^LF) :-
   !,
   check_lexical_entry_type(LF).
check_lexical_entry_type(LF) :-
   LF =.. [Functor | Args],
   length(Args, N),
   length(BlankArgs, N),
   BlankLF =.. [Functor | BlankArgs],
   predicate_type(_, BlankLF),
   !.
check_lexical_entry_type(LF) :-
   log(no_type_specified_for(LF)).