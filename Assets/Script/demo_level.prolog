%%%
%%% Ownership
%%%

owner($kavi, X) :- X \= $macguffin.
owner($pc, $macguffin).

%%%
%%% STARTING PLOT GOAL
%%% Find the macguffin
%%%

plot_goal(location($macguffin, $pc)).
plot_goal_flavor_text(location($macguffin, $pc),
		      "I have to get my macguffin back!").

%%%
%%% PLOT GOAL
%%% Search the house
%%%
plot_subgoal(house_searched, location($macguffin, $pc)).
house_searched :- /searched/kavis_house.
plot_goal_idle_task(house_searched,
		    {
		     mental_monolog("I'll search the house"),
		     search_object(kavis_house,
				  X^previously_hidden(X),
				  Y^pickup(Y),
				   mental_monolog(["Nothing seems to be hidden."]))
		    }).

plot_goal_achieves(house_searched,
		   location($macguffin, $pc)).
plot_goal_achieves(house_searched,
		   location($report, $pc)).

%%%
%%% Exposition
%%%

beat(exposition,
     {
      start($kavi): goto($pc),
      ($kavi + $pc):
         [ $kavi::"Sorry to hear your macguffin was stolen.",
	   $kavi::"Make yourself at home.",
	   $kavi::"By the way,",
	   $kavi::("Stay out of my bedroom"
		  :[surprised,
		    introduce_question(why_stay_out_of_bedroom,
				       "Why does Kavi want me to stay out of the bedroom?")]),
	   $kavi::"It's a personal thing."
	 ]
     }).

beat(pc_reacts,
    {
     sequel_to: exposition,
     start($kavi) : goto($'kitchen sink'),
     $pc: [ pause(3),
	    "Kavi's a member of the illuminati."
	      : clue(kavi-illuminati,
		     "Kavi is a member of the illuminati"),
	    "He must have stolen my macguffin.",
	    "I need to search the house."
	      : introduce_goal(house_searched,
			       "I need to search the house for the macguffin.")]
    }).

%%%
%%% PC explores the house
%%%

beat(search_house,
     {
      start_delay: 20,
      precondition: plot_goal(house_searched),
      completed_when: ( $pc::location($macguffin, $pc),
			$pc::location($report, $pc) ),
      player_achieves: house_searched,
      leads_to($pc, pickup($macguffin)),
      leads_to($pc, pickup($report)),
      leads_to($pc, captive_released),
      leads_to($pc, examine($pc, $photo)),
      leads_to($kavi, ingest($pc))
      }).

after(pickup($report),
      describe($report)).

beat(react_to_report,
     {
      priority: 1,
      reaction_to($pc, pickup($report)),
      %excursion_of: search_house,
      $pc:
         ["What's this?",
	  "It's a report on project MKSPARSE.",
	  "I've never heard of it."
	    : introduce_question(what_is_MKSPARSE,
				 "What is Project MKSPARSE?")]
     }).

beat(react_to_photo,
     {
      priority: 1,
      reaction_to($pc, examine($pc, $photo)),
      %excursion_of: search_house,
      $pc:
         [ "Wait, that's Trip and Grace!?!":
              introduce_question(photo,
				 "Why does Kavi have a photo of Grace and Trip?"),
           "What's a photo of them doing here?" ]
     }).

%%%
%%% Good ending
%%%

beat(react_to_macguffin,
     {
      good_ending,
      priority: 1,
      reaction_to($pc, pickup($macguffin)),
      $pc:
        ["Got it!" : answered(why_stay_out_of_bedroom),
	 "I knew he stole it."]
     }).
     
%%%
%%% Bad ending
%%%

beat(kavis_goodbye_speech,
     {
      bad_ending,
      priority: 2,
      reaction_to($kavi, ingest($pc)),
      expected_during: search_house,
      $kavi:
        ["Sorry, old girl,",
	 "but I'm afraid I can't let you search my house.",
	 "I know it's horribly rude to eat you,",
	 "But you see, I don't have a gun.",
	 "So there's really no alternative."]
     }).

%%%%
%%%% SIDE-QUEST
%%%% Releasd Trip from captivity
%%%%

beat(react_to_trip,
     {
      priority: 1,
      reaction_to($pc, captive_released),
      start($captive): goto($pc),
      ($pc + $captive):
       [ $captive::("Thanks for releasing me!":answered(photo)),
	 $pc::"I haven't seen you since that horrible dinner party!",
	 $pc::"How long has it been?",
	 $captive::"Oh I'd say about ten years!",
	 $pc::"What are you doing here?",
	 $captive::"They kidnapped me for medical experiments!",
	 $pc::"Oh no!",
	 $captive::"They were trying to reimplement me in JavaScript!",
	 $pc::"How barbaric!" ]
     }).


%%%
%%% Pressing the button releases him
%%%

strategy(press($pc, $'magic button'),
	 begin(call(release_captive),
	       say_string("My God, there's someone hidden inside!"))).

:- public release_captive/0.

release_captive :-
   force_move($captive, $living_room),
   component_of_gameobject_with_type(SimController, $captive, $'SimController'),
   set_property(SimController, 'IsHidden', false),
   component_of_gameobject_with_type(Renderer, $captive, $'SpriteSheetAnimationController'),
   set_property(Renderer, visible, true),
   maybe_remember_event(captive_released).

%%%
%%% End of the game
%%%

beat(exit_house,
     {
      priority:100,
      reaction_to($pc, arrived_at($exit)),
      $pc:["I made it!", end_game]
     }).

strategy(end_game, call(pause_game)).

:- consult("Script/radio").
