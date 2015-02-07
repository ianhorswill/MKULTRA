build_reduction_cross_reference :-
   retractall(reduces_to(_,_)),
   forall(clause(strategy(Goal, Reduction), _Guard),
	  assert_reductions(Goal, Reduction)).

assert_reductions(Goal, Subgoal) :-
   var(Subgoal),
   !,
   functor(Goal, Name, Arity),
   ensure(reduces_to_aux(Name, Arity, reduction_is_a_variable, 0)).
assert_reductions(_, null) :-
   !.
assert_reductions(Goal, (X, Y)) :-
   !,
   assert_reductions(Goal, X),
   assert_reductions(Goal, Y).
assert_reductions(Goal, Subgoal) :-
   functor(Goal, GN, GA),
   functor(Subgoal, SN, SA),
   ensure(reduces_to_aux(GN, GA, SN, SA)).

:- build_reduction_cross_reference.

reduces_to(G/GA, S/SA) :-
   reduces_to_aux(G, GA, S, SA).

bad_reduction(G/GA, R/RA) :-
   reduces_to_aux(G, GA, R, RA),
   \+ primitive_task(R, RA),
   \+ reduces_to_aux(R, RA, _, _).

test(problem_solver(undeclared_tasks),
     [ true(SortedBadReductions == []) ]) :-
   all((Reduction:Goal),
       bad_reduction(Goal, Reduction),
       BadReductions),
   all(Subgoal,
       member((Subgoal:_), BadReductions),
       BadSubgoals),
   all(Subgoal:Callers,
       ( member(Subgoal, BadSubgoals),
	 all(Caller,
	     member((Subgoal:Caller), BadReductions),
	     Callers) ),
       SortedBadReductions).

primitive_task(reduction_is_a_variable, 0).
primitive_task(call, 1).
primitive_task(invoke_continuation, 1).
primitive_task(assert, 1).
primitive_task(retract, 1).
primitive_task(let, 2).
primitive_task(wait_condition, 1).
primitive_task(wait_event, 1).
primitive_task(wait_event_with_timeout, 2).
primitive_task(Name, Arity) :-
   action_functor(Name, Arity).

