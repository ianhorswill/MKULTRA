%%
%% Auxilliary verb forms (do have, be)
%%

:- randomizable aux_do//2.
aux_do(present, Agreement) -->
	[ do ],
	{ Agreement \= third:singular }.
aux_do(present, third:singular) -->
	[ does ].
aux_do(past, _Agreement) --> [did].

:- randomizable aux_have//2.
aux_have(present, Agreement) -->
	[ have ],
	{ Agreement \= third:singular }.
aux_have(present, third:singular) -->
	[ has ].
aux_have(past, _Agreement) --> [had].
aux_have(future, _Agreement) --> [have].

:- randomizable aux_be//2.
aux_be(present, first:singular) -->
	[ am ].
aux_be(present, second:singular) -->
	[ are ].
aux_be(present, third:singular) -->
	[ is ].
aux_be(present, _:plural) -->
	[ are ].
aux_be(past, first:singular) -->
	[ was ].
aux_be(past, second:singular) -->
	[ were ].
aux_be(past, third:singular) -->
	[ was ].
aux_be(past, _:plural) -->
	[ were ].
aux_be(future, _Agreement) --> [be].

:- randomizable opt_not//1.
opt_not(affirmative) --> [ ].
opt_not(negative) --> [not].
