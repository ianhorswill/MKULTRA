generate_text(DialogAct, _Recipient, Text) :-
    randomize(utterance(DialogAct, Words, [ ])),
    word_list(Text, Words).
