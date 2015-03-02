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

