%%
%% Conflict strategies
%% Preference relations and random selection.
%%

strategy(resolve_conflict(T, L), pick_randomly(L)).
strategy(resolve_conflict(T, L), pick_preferred(T, L)) :-
   % Pick preferred strategy if there's a preference relation defined for this task.
   once(prefer_strategy(T, _, _)).

%%
%% Null strategies
%%

strategy(resolve_match_failure(T), restart(T)) :-
   \+ $task/restart_attempted.
strategy(restart(T),
	 ( call(assert($task/restart_attempted)),
	   continue(Goal, null) )) :-
   $task/type:task:Goal.
% Restart is last resort.
prefer_strategy(resolve_match_failure(_), _, restart(_)).

strategy(resolve_match_failure(resolve_conflict(T, L)),
	 DefaultStrategy) :-
   (preferences_defined(T) ->
       DefaultStrategy = pick_preferred(T,L)
       ;
       DefaultStrategy = pick_randomly(L)).

strategy(pick_randomly(List), X) :-
   % Pick randomly; need once/1, or it just regenerates the whole list.
   once(random_member(X, List)).

strategy(pick_preferred(Task, List), Preferred) :-
   preferred_strategy(Task, List, Preferred).

preferred_strategy(Task, [First | Rest], Preferred) :-
   max_preference(Task, First, Rest, Preferred).

max_preference(Task, Default, [], Default).
max_preference(Task, Default, [First | Rest], Max) :-
   prefer_strategy(Task, First, Default),
   !,
   max_preference(Task, First, Rest, Max).
max_preference(Task, Default, [_ | Rest], Max) :-
   max_preference(Task, Default, Rest, Max).

%% prefer_strategy(+Task, +PreferredStrategy, +DispreferredStrategy)
%  PreferredStrategy is better for solving Task than DispreferredStrategy.
