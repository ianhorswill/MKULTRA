:- public generate_text/3.

generate_text(DialogAct, _Recipient, Text) :-
    randomize(utterance(DialogAct, Words, [ ])),
    word_list(Text, Words).
