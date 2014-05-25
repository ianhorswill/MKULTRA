construals(Event, ConstrualList) :-
    all(Construal, construal(Event, Construal), ConstrualList).

construal(Event, Event).
construal(Event, Construal) :-
    is_also(Event, C), construal(C, Construal).


