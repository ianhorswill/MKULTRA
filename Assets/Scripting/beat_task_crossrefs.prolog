reduction_clause(beat_start_task(Beat), StartTask) :-
   beat_start_task(Beat, _, StartTask).
reduction_clause(beat_idle_task(Beat), IdleTask) :-
   beat_idle_task(Beat, _, IdleTask).
reduction_clause(beat_tasks(Beat), Task) :-
   beat_tasks(Beat, TaskList),
   member(Task, TaskList).

reduction_clause(Goal, quip) :-
   character(C),
   C::clause(quip(Goal, _QuipName, _), _),
   nonvar(Goal).
reduction_clause(Goal, quip) :-
   character(C),
   C::clause(quip(Goal, _), _),
   nonvar(Goal).

ignore_undeclared_task(quip,0).