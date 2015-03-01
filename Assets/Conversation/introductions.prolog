%%%
%%% Special rules for describing people
%%%

strategy(introduce_person(Person),
	 begin(maybe_give_name(Person),
	       describe(Person, introduction, null))).

strategy(maybe_give_name($me),
	 say(be($me, Name))) :-
   property_value($me, given_name, Name).

strategy(maybe_give_name(X),
	 null) :-
   X \= $me.

property_relevant_to_purpose(introduction, _, Property, _) :-
   memberchk(Property, [age, gender, job]).
property_relevant_to_purpose(general, _, _, _).

relation_relevant_to_purpose(introduction, _, Relation, _) :-
   memberchk(Relation, [ interested_in, knows_about, roommate_of ]).
relation_relevant_to_purpose(general, _, _, _).

