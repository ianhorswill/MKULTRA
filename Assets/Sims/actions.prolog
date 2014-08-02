%%%
%%% Actions and tasks
%%%

%% precondition(?Action, ?P)
%  P is a precondition of Action.

:- external precondition/2.

%% achieves(?Action, ?Effect)
%  Action can be expected to achieve Effect

:- external achieves/2.

%% decomposition(+Task, -Decomposition)
%  Decomposition is a decomposition of Task.

:- external decomposition/2.

%% action(?Task)
%  True if Task is a primitive task, i.e. an action.

action(T) :-
   nonvar(T),
   functor(T, F, A),
   action_functor(F, A).
action(T) :-
   var(T),
   action_functor(F, A),
   functor(T, F, A).

%% action_functor(?Functor, ?Arity)
%  True when any structor with the specified Functor and Arity
%  is a primitive action.

:- external action_functor/2.

%% runnable(+Action) is det
%  True if Action can be executed now.
runnable(Action) :-
   \+ blocking(Action, _).

%% blocking(+Action, ?Precondition) is det
%  Action cannot be run because Precondition is an unsatisfied precondition of P.
blocking(Action, P) :-
   precondition(Action, P),
   \+ P.

%%
%% Builtin primitive actions handled in SimController.cs
%%

action_functor(pickup, 1).
precondition(pickup(X),
	     docked_with(X)).

action_functor(putdown, 2).
precondition(putdown(Object, _Dest),
	     location(Object, $me)).
precondition(putdown(_Object, Dest),
	     docked_with(Dest)).

action_functor(ingest, 1).
precondition(ingest(Edible),
	     location(Edible, $me)).