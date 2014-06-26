:- public generate_text/2, input_completion/3.

%% generate_text(?SpeechAct, ?Text)
%  The string Text is a possible realization of SpeechAct.
generate_text(SpeechAct, Text) :-
   bind_dialog_indexicals_for_output(SpeechAct),
   step_limit(10000),
   randomize(utterance(SpeechAct, Words, [ ])),
   contracted_form(Words, Contracted),
   word_list(Text, Contracted).

%% input_completion(+InputText, -CompletionText, -SpeechAct)
%  InputText followed by CompletionText is a possible realization of SpeechAct.
input_completion(InputText, CompletionText, SpeechAct) :-
   bind_dialog_indexicals_for_input,
   word_list(InputText, InputWords),
   contracted_form(InputUncontracted, InputWords),
   append(InputUncontracted, CompletionUncontracted, AllWords),
   %call_with_step_limit(10000, randomize(utterance(SpeechAct, AllWords, []))),
   step_limit(10000),
   randomize(utterance(SpeechAct, AllWords, [])),
   contracted_form(CompletionUncontracted, CompletionWords),
   word_list(CompletionText, CompletionWords).

bind_dialog_indexicals_for_input :-
   bind(speaker, $me),
   bind(addressee, $me),
   bind(dialog_group, $me).

bind_dialog_indexicals_for_output(SpeechAct) :-
   agent(SpeechAct, A),
   patient(SpeechAct, P),
   bind(speaker, A),
   bind(addressee, P).