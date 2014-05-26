:- public generate_text/2.

generate_text(DialogAct, Text) :-
    randomize(utterance(DialogAct, Words, [ ])),
    word_list(Text, Words).
