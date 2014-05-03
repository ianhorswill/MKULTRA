why(P) :-
	clause(P,B),
	copy_term((P:-B), Rule),
	B,
	write('rule: '), writeln(Rule),
	write('bindings: '), writeln((P :- B)).

why_not(P) :-
	clause(P,B),
	copy_term((P:-B), Rule),
	write('rule: '), write(Rule), nl,
	diagnose_failure(B),
	fail.
why_not(P) :-
	clause(P, _).
why_not(_) :-
	writeln('No rules match goal.').
diagnose_failure((A,B)) :-
	!, (diagnose_failure(A) ; diagnose_failure(B)).
diagnose_failure(P) :-
	\+ P,
	write('   fails at: '), write(P), nl.
