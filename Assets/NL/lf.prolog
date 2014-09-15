%%
%% Predicates for manipulating logical forms
%%

%% lf_main_predicate(:LF, -Core)
%  Strips ancillary conjuncts from LF and returns its main predicate,
%  including modals and/or question operators.
lf_main_predicate((P, _), C) :-
   !,
   lf_main_predicate(P, C).
lf_main_predicate(P,P).

%% lf_core_predicate(?LF, ?Predication)
%  If LF is bound, strips its conjuncts and modals to return just the predication of the main verb.

lf_core_predicate(S, _) :-
   var(S), !.  % do nothing if we don't know what the sentence LF is.
lf_core_predicate(_:S, P) :-
   !,
   lf_core_predicate(S, P).
lf_core_predicate(explanation(S,_), P) :-
   !,
   lf_core_predicate(S, P).
lf_core_predicate(not(S), P) :-
   !,
   lf_core_predicate(S, P).
lf_core_predicate(may(S), P) :-
   !,
   lf_core_predicate(S, P).
lf_core_predicate(should(S), P) :-
   !,
   lf_core_predicate(S, P).
lf_core_predicate(can(S), P) :-
   !,
   lf_core_predicate(S, P).
lf_core_predicate(must(S), P) :-
   !,
   lf_core_predicate(S, P).
lf_core_predicate(S, S).


%% lf_subject(?LF, ?Subject)
%  If LF is bound, binds Subject to the term representing the subject of the main verb in LF.

% Don't do anything if S is uninstantiated
lf_subject(LF, _) :-
   var(LF), !.
lf_subject(LF, Subject) :-
   lf_core_predicate(LF, P),
   lf_core_predicate_subject(P, Subject).

lf_core_predicate_subject(be(Subject), Subject) :-
   !.
lf_core_predicate_subject(related(Subject, _, _), Subject):-
   !.
lf_core_predicate_subject(S, Subject) :-
   intransitive_verb(_, _, _, _, _, _, Subject^S).
lf_core_predicate_subject(S, Subject) :-
   transitive_verb(_, _, _, _, _, _, Subject^_^S).
lf_core_predicate_subject(S, Subject) :-
   ditransitive_verb(_, _, _, _, _, _, Subject^_^_^S).
lf_core_predicate_subject(S, Subject) :-
   adjective(_, Subject^S).

