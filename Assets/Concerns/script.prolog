:- indexical script_concern=unknown_concern.

on_enter_state(start, script, C) :-
   (C/history:History
     ;
     (History=[ ], assert(C/history:History))),
   update_awaiting(C, History).

on_event(Event, script, C, update_script(C, Event)) :-
   C/awaiting:Events,
   memberchk(Event, Events).
   
propose_action(Action, script, C) :-
   /perception/nobody_speaking,
   C/awaiting:Events,
   member(Action, Events),
   action(Action),
   agent(Action, $me).

update_script(C, Event) :-
    C/history:History,
    append(History, [Event], NewHistory),
    assert(C/history:NewHistory),
    update_awaiting(C, NewHistory).

update_awaiting(C, NewHistory) :-
   C/type:script:Script,
   bind(script_concern, C),
   next_events(Script, NewHistory, NextSet),
   ((NextSet = [ ]) ->
      kill_concern(C)
      ;
      assert(C/awaiting:NextSet)).
