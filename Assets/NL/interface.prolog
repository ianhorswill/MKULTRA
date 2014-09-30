:- public generate_text/2, input_completion/3.
:- indexical input_from_player=false,
   generating_nl=false,
   discourse_variables=null.

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
   in_conversation_with_npc(NPC),
   !,
   bind(input_from_player, true),
   bind(speaker, $me),
   bind(addressee, NPC),
   bind(dialog_group, $me).
bind_dialog_indexicals_for_input :-
   bind(input_from_player, true),
   bind(speaker, player),
   bind(addressee, $me),
   bind(dialog_group, $me).

bind_indexicals_for_addressing_character_named(Name) :-
   proper_noun(Name, Character),
   character(Character),
   bind(speaker, $me),
   bind(addressee, Character).

in_conversation_with_npc(NPC) :-
   concern(C),
   C/partner/NPC,
   NPC \= player.

bind_dialog_indexicals_for_output(SpeechAct) :-
   bind(generating_nl, true),
   bind(discourse_variables, null),
   agent(SpeechAct, A),
   patient(SpeechAct, P),
   bind(speaker, A),
   bind(addressee, P).

generating_nl :-
   X = $generating_nl, X.

input_from_player :-
   X = $input_from_player, X.