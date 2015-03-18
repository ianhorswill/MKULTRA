%%%
%%% Code for talking to other parts of the C# code
%%%

%% emit_grain(+SoundName, +Duration) is det
%  Plays a grain of sound with the specified duration in ms.
emit_grain(Name, Duration) :-
   $this \= $me,
   $this.'EmitGrain'(Name, Duration),
   !.
emit_grain(_,_).

:- public fkey_command/1.
:- external fkey_command/1.

%% fkey_command(+FKeySymbol)
%  Called by UI whenever a given F-key is pressed.
