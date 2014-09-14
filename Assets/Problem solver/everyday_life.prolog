%%
%% The "everyday life" task.
%%
%% Periodically searches for stuff to do.
%%

character_initialization :-
   start_task(everyday_life, 100).

strategy(everyday_life,
	 ( achieve(P), everyday_life )) :-
   maintenance_goal(P),
   \+ P,
   % Make sure that P isn't obviously unachievable.
   once(strategy(achieve(P), _)).


default_strategy(everyday_life,
		 ( wait_event_with_timeout(_, 60),
		   everyday_life )).

maintenance_goal(~hungry).
hungry :- /physiological_states/hungry.
~hungry :- \+ hungry.

maintenance_goal(~thirsty).
thirsty :- /physiological_states/thirsty.
~thirsty :- \+ thirsty.

maintenance_goal(~tired).
tired :- /physiological_states/tired.
~tired :- \+ tired.

maintenance_goal(~dirty).
dirty :- /physiological_states/dirty.
~dirty :- \+ dirty.

maintenance_goal(~full_bladder).
full_bladder :- /physiological_states/full_bladder.
~full_bladder :- \+ full_bladder.




