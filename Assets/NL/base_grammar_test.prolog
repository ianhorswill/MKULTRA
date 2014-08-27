test(completion(s, what_is_on),
     [ true( nonempty_instantiated_atom_list(Completion) ),
       nondet ]) :-
   s_test(_, interrogative, [what, is, on | Completion]).

test(completion(s, imperative),
     [ true( nonempty_instantiated_atom_list(Completion) ),
       true(Mood == imperative),
       nondet ]) :-
   s_test(_, Mood, [go, to | Completion]).

test(generate(s, in_expression)) :-
   s_test(location($'Kavi', $'kitchen'), indicative, Generated),
   Generated == ['Kavi', is, in, the, kitchen ].

test(generate(s, future_indicative),
     [ setup(bind(speaker, $'Bruce')),
       true(Generated == ['I', will, eat, the, plant]),
       nondet ]) :-
   s(eat($'Bruce', $plant), indicative, affirmative, future, simple, Generated, [ ]).

test(parse(s, imperative),
     [ setup(bind(addressee, $'Bruce')),
       true(LF == go($'Bruce', $bed)),
       true(Mood == imperative),
       nondet]):-
   s_test(LF, Mood, [go, to, the, bed]).

s_test(LF, Mood, SurfaceForm) :-
   s(LF, Mood, affirmative, present, simple, SurfaceForm, [ ]).