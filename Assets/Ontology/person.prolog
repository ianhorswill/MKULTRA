has_property(human, given_name).
has_property(human, surname).
has_property(human, gender).
adjectival_property(gender).
property_extension(gender,
		   [male, female]).
has_property(human, job).
nominal_property(job).
valid_property_value(job, X) :-
   atom(X).
has_property(human, age).
adjectival_property(age).
valid_property_value(age, X) :-
   number(X).

has_relation(human, knows_about).
has_relation(human, interested_in).
copular_relation([interested, in], interested_in).
has_relation(human, member_of).
copular_relation([a, member, of], member_of).
has_relation(human, friend_of).
copular_relation([a, friend, of], friend_of).
has_relation(human, roommate_of).
copular_relation([a, roommate, of], roommate_of).
copular_relation([the, roommate, of], roommate_of).
has_relation(human, knows).
has_relation(human, likes).
has_relation(human, loves).
has_relation(human, hates).

implies_relation(interested_in, knows_about).
implies_relation(loves, friend_of).
implies_relation(friend_of, likes).
implies_relation(knows, knows_about).
implies_relation(roommate_of, knows).
implies_relation(likes, knows).
implies_relation(member_of, knows_about).


:- declare_object($'Bruce',
		  [ age=23,
		    given_name="Bruce",
		    surname="Bigelow",
		    gender=male,
		    job=spy ],
		  [ knows_about: spying,
		    interested_in: cia,
		    member_of: illuminati,
		    friend_of: $'Kavi',
		    roommate_of: $'Kavi',
		    loves: $'Kavi' ]).


:- declare_object($'Kavi',
		  [ age=23,
		    given_name="Kavi",
		    surname="Surkow",
		    gender=male,
		    job=barista ],
		  [ knows_about: coffee,
		    interested_in: tamping,
		    friend_of: $'Bruce',
		    roommate_of: $'Bruce' ]).
