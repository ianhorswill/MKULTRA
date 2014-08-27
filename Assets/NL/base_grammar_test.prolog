test(completion(s, what_is_on),
     [ true( nonempty_instantiated_atom_list(Completion) ),
       nondet ]) :-
   s_test(_, interrogative, [what, is, on | Completion]).

test(generate(s, in_expression)) :-
   s_test(location($'Kavi', $'kitchen'), indicative, Generated),
   Generated == ['Kavi', is, in, the, kitchen ].

test(generate(s, future_indicative),
     [ true(Generated == ['Bruce', will, eat, the, plant]),
       nondet ]) :-
   s(eat($'Bruce', $plant), indicative, affirmative, future, simple, Generated, [ ]).

s_test(LF, Mood, SurfaceForm) :-
   s(LF, Mood, affirmative, present, simple, SurfaceForm, [ ]).