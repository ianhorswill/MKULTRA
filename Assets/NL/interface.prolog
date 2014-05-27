:- public generate_text/2, input_completion/3.

%% generate_text(?SpeechAct, ?Text)
%  The string Text is a possible realization of SpeechAct.
generate_text(SpeechAct, Text) :-
    randomize(utterance(SpeechAct, Words, [ ])),
    word_list(Text, Words).

%% input_completion(+InputText, -CompletionText, -SpeechAct)
%  InputText followed by CompletionText is a possible realization of SpeechAct.
input_completion(InputText, CompletionText, SpeechAct) :-
    word_list(InputText, InputWords),
    append(InputWords, CompletionWords, AllWords),
    randomize(utterance(SpeechAct, AllWords, [])),
    word_list(CompletionText, CompletionWords).
