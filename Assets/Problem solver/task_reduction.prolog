%%
%% Goal reduction
%%

task_reduction(Task, Reduction) :-
   begin(canonical_form_of_task(Task, Canonical),
	 reduce_canonical_form(Canonical, Reduction)).
reduce_canonical_form(Task, Task) :-
   primitive_task(Task),
   !.
reduce_canonical_form(Canonical, Reduction) :-
   begin(matching_strategies(Strategies, Canonical),
	 selected_reduction_with_before_after(Canonical, Strategies, Reduction)).

% Select method and attach befor and after
selected_reduction_with_before_after(Canonical, Strategies, Joined) :-
   begin(selected_reduction(Canonical, Strategies, Selected),
	 all(Method,
	     before(Canonical, Method),
	     BeforeMethods),
	 all(Method,
	     after(Canonical, Method),
	     AfterMethods),
	 append_task_lists(BeforeMethods, Selected, AfterMethods, Joined)).

% Select the reduced method from available methods.
selected_reduction(_, [S], S).
selected_reduction(Task, [ ], resolve_match_failure(Task)) :-
   emit_grain("match fail", 10).
selected_reduction(Task, Strategies, resolve_conflict(Task, Strategies)) :-
   emit_grain("match conflict", 10).

%%
%% Canonical forms
%%

canonical_form_of_task(Task, Canon) :-
   normalize_task(Task, Normalized),
   canonical_form_of_task(Normalized, Canon),
   !.
canonical_form_of_task(Task, Task).

%%
%% Standard normalizations
%%

normalize_task(if(Condition, Then, _Else),
	  Then) :-
   Condition,
   !.
normalize_task(if(_, _, Else),
	  Else).
normalize_task(cases(CaseList),
	       S) :-
   member(C:S, CaseList),
   C,
   !.

normalize_task(begin(A, B),
	       (A, B)).
normalize_task(begin(A, B, C),
	       (A, B, C)).
normalize_task(begin(A, B, C, D),
	       (A, B, C, D)).
normalize_task(begin(A, B, C, D, E),
	       (A, B, C, D, E)).
normalize_task(begin(A, B, C, D, E, F),
	       (A, B, C, D, E, F)).

% Translate wait_event_with_timeout into wait_event/2,
% which has a deadline rather than a timeout period.
normalize_task(wait_event_with_timeout(E, TimeoutPeriod),
	       wait_event(E, Deadline)) :-
   Deadline is $now + TimeoutPeriod.

%%
%% Matching strategies to tasks
%%

matching_strategies(Strategies, Task) :-
   all(S,
       matching_strategy(S, Task),
       Strategies).

%% matching_strategy(-S, +Task)
%  S is a strategy for Task.
matching_strategy(S, Task) :-
   (personal_strategy(Task, S) ; strategy(Task, S)),
   emit_grain("Default", 3),
   \+ veto_strategy(Task).

%%
%% Debugging tools
%%

%% show_decomposition(+Task)
%  Prints the series of decompositions of Task until it reaches a point where
%  it's not further decomposable, or the decomposition is non-unique.
show_decomposition(Task) :-
   writeln(Task),
   task_reduction(Task, Reduced),
   show_decomposition_aux(Reduced).

show_decomposition_aux(resolve_match_failure(_)) :-
   writeln('-> no further decompositions possible').
show_decomposition_aux(resolve_conflict(_, ListOfReductions)) :-
   writeln('->'),
   forall(member(R, ListOfReductions),
	  begin(write('   '),
		writeln(R))).
show_decomposition_aux(UniqueDecomposition) :-
   write('-> '),
   writeln(UniqueDecomposition),
   task_reduction(UniqueDecomposition, Reductions),
   show_decomposition_aux(Reductions).

%%%
%%% General utilities
%%%

%% append_task_lists(+Start, +End, -Joined) is det
append_task_lists(X, null, X).
append_task_lists(null, X, Y) :-
   % We have to do this to comafy X :(
   append_task_lists(X, null, Y).
append_task_lists([First], X, (First, X)).
append_task_lists([First | Rest], X, (First, Y)) :-
   append_task_lists(Rest, X, Y).
append_task_lists(First, X, [First | Y]) :-
   append_task_lists(X, null, Y).

append_task_lists(X, Y, Z, Joined) :-
   append_task_lists(Y, Z, Intermediate),
   append_task_lists(X, Intermediate, Joined).