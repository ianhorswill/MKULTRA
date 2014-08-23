:- public load_csv_row/2.
:- public begin_csv_loading/1, end_csv_loading/1.
:- external begin_csv_loading/1, end_csv_loading/1.

load_csv_row(Row, Assertion) :-
   load_special_csv_row(Row, Assertion).
load_csv_row(_, Assertion) :-
   assertz(Assertion).