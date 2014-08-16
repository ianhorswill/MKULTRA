has_property(human, given_name).
has_property(human, surname).
has_property(human, gender).
copular_property(gender).
has_property(human, job).
copular_property(job).
has_property(human, age).
copular_property(age).

has_relation(human, knows_about).
has_relation(human, interested_in).
has_relation(human, member_of).
has_relation(human, friend_of).
has_relation(human, knows).
has_relation(human, likes).
has_relation(human, loves).
has_relation(human, hates).
has_relation(human, roommate_of).

implies_relation(interested_in, knows_about).
implies_relation(loves, friend_of).
implies_relation(friend_of, likes).
implies_relation(knows, knows_about).
implies_relation(likes, knows).


:- declare_object($'Bruce',
		  [ age=23,
		    %given_name='Bruce',
		    %surname='Bigelow',
		    gender=male,
		    job=spy ],
		  [ knows_about: spying,
		    interested_in: cia,
		    member_of: illuminati,
		    friend_of: $'Kavi',
		    loves: $'Kavi' ]).
