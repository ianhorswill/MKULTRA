adjectival_property(gender).
nominal_property(job).
valid_property_value(job, X) :-
   kind_of(X, job).
adjectival_property(age).
valid_property_value(age, X) :-
   number(X).

:- declare_object($'Bruce',
		  [ age=23,
		    given_name="Bruce",
		    surname="Bigelow",
		    gender=male,
		    job=spy ],
		  [ knows_about: spying,
		    interested_in: cia,
		    friend_of: $'Kavi' ]).

:- declare_object($'Kavi',
		  [ age=23,
		    given_name="Kavi",
		    surname="Surkow",
		    gender=male ],
		  [ member_of: illuminati,
		    friend_of: $'Bruce' ]).
