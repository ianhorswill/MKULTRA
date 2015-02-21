:- public load_csv_row/2.
:- public begin_csv_loading/1, end_csv_loading/1.
:- external begin_csv_loading/1, end_csv_loading/1.

load_csv_row(Row, Assertion) :-
   load_special_csv_row(Row, Assertion).
load_csv_row(_, Assertion) :-
   assertz(Assertion).

:- randomizable proper_name/4, proper_name/2.

%% assert_proper_name(+Object, +Name, +Number) is det
%  Asserts that Object has proper name Name (a list of words) with
%  gramatical number Number (singular or plural).
%  Functionally, this means it adds the grammar rule:
%    proper_name(Object, Number) --> Name.
assert_proper_name(Object, [ ], NumberSpec) :-
   !,
   assert_proper_name(Object, [Object], NumberSpec).
assert_proper_name(Object, Name, NumberSpec) :-
   assertion(\+ (member(X, Name), \+ atomic(X)),
	     Name:"Proper name must be a list of symbols"),
   append(Name, Tail, NameWithTail),
   (number_spec_number(NumberSpec, Number) -> 
       assertz(proper_name(Object, Number, NameWithTail, Tail))
       ;
       log(bad_grammatical_number(NumberSpec:Name))).

% This is just to handle defaulting of number to singular, and to
% catch mistyped number.
number_spec_number([ ], singular).
number_spec_number(singular, singular).
number_spec_number(plural, plural).
