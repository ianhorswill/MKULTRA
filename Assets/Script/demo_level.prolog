plot_goal(location($macguffin, $pc)).
plot_goal_flavor_text(location($macguffin, $pc),
		      "I have to get my macguffin back!").

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
   react_to_plot_event(release_captive).

plot_point(release_captive,
	   $global_root/plot_points/captive_released).

%%%
%%% Exposition beat
%%%

beat(exposition).
beat_start_task(exposition,
		$kavi,
		goto($pc)).
beat_dialog(exposition,
	    $pc, $kavi,
	    [ %read_instructions($intro_screen),
	      mention_macguffin,
	      mention_keepout
              %, read_instructions($instructions)
	    ]).

$kavi::quip(mention_macguffin,
	    ["Sorry to hear your macguffin was stolen.",
	     "Make yourself at home."]).
$kavi::quip(mention_keepout,
	    ["By the way,",
	     "Stay out of my bedroom"
	    :[surprised,
	      introduce_question(why_stay_out_of_bedroom,
				 "Why does Kavi want me to stay out of the bedroom?")],
	     "It's a personal thing."]).

$pc::personal_strategy(read_instructions(X),
		       force_examine(X)).

%%%
%%% PC reacts to Kavi's speech
%%%

beat(pc_reacts).
beat_sequel(pc_reacts, exposition).
beat_start_task(pc_reacts, $kavi, goto($'kitchen sink')).
beat_monolog(pc_reacts,
	     $pc,
	     [ pause(3),
	       "I'm sure Kavi stole my macguffin.",
	       "It must be here someplace.",
	       "He's a member of the illuminati." : clue(kavi-illuminati, "Kavi is a member of the illuminati"),
	       "I need to search the house." : introduce_goal(house_searched, "I need to search the house for the macguffin.")]).

plot_subgoal(house_searched, location($macguffin, $pc)).
house_searched :- /searched/kavis_house.

%%%
%%% PC explores the house
%%%

beat(pc_explores_the_house).
beat_delay(pc_explores_the_house, 20).
beat_follows(pc_explores_the_house, pc_reacts).
beat_completion_condition(pc_explores_the_house,
			  ( $pc::contained_in($macguffin, $pc),
			    $pc::contained_in($report, $pc) )).
beat_idle_task(pc_explores_the_house,
	       $pc,
	       search_object(kavis_house,
			     X^previously_hidden(X),
			     Y^pickup(Y),
			     mental_monologue(["Nothing seems to be hidden."]))).

after(pickup($report),
      describe($report)).

%%%
%%% PC finds the report
%%%

beat(pc_finds_the_report).
beat_priority(pc_finds_the_report, 1).
beat_precondition(pc_finds_the_report,
		  $pc::contained_in($report, $pc)).
beat_monolog(pc_finds_the_report,
	     $pc,
	     ["What's this?",
	      "It's a report on project MKSPARSE.",
	      "I've never heard of it." : introduce_question(what_is_MKSPARSE,
							     "What is Project MKSPARSE?")]).

%%%
%%% PC finds the photo
%%%

beat(pc_finds_the_photo).
beat_priority(pc_finds_the_photo, 1).
beat_precondition(pc_finds_the_photo,
		  examined($photo)).
beat_monolog(pc_finds_the_photo,
	     $pc,
	     [ "Wait, that's Trip and Grace!?!": introduce_question(photo,
								    "Why does Kavi have a photo of Grace and Trip?"),
	       "What's a photo of them doing here?" ]).

%%%
%%% Pc finds the macguffin
%%%

beat(pc_finds_the_macguffin).
beat_priority(pc_finds_the_macguffin, 1).
beat_precondition(pc_finds_the_macguffin,
		  $pc::contained_in($macguffin, $pc)).
beat_monolog(pc_finds_the_macguffin,
	     $pc,
	     ["Got it!" : answered(why_stay_out_of_bedroom),
	      "I knew he stole it."]).

%%%
%%% PC releases captive
%%%

beat(pc_releases_captive).
beat_priority(pc_releases_captive, 1).
beat_precondition(pc_releases_captive,
		  $global_root/plot_points/captive_released).
beat_start_task(pc_releases_captive,
		$captive,
		goto($pc)).
beat_dialog(pc_releases_captive, $pc, $captive,
	    [ thanks_for_releasing_me,
	      its_been_so_long,
	      about_ten_years,
	      what_are_you_doing_here,
	      medical_experiments,
	      oh_no,
	      javascript,
	      barbaric ]).

$captive::quip(thanks_for_releasing_me,
	       [ "Thanks for releasing me!" ]).
$pc::quip(its_been_so_long,
	  [ "I haven't seen you since that horrible dinner party!",
	    "How long has it been?" ]).
$captive::quip(about_ten_years,
	       [ "Oh I'd say about ten years!" ]).
$pc::quip(what_are_you_doing_here,
	  [ "What are you doing here?" ]).
$captive::quip(medical_experiments,
	       [ "They kidnapped me for medical experiments!" ]).
$pc::quip(oh_no,
	  [ "Oh no!" ]).
$captive::quip(javascript,
	       [ "They were trying to reimplement me in JavaScript!" ]).
$pc::quip(barbaric,
	  [ "How barbaric!" ]).

     
%%%
%%% Kavi eats Pc
%%%

beat(kavi_eats_pc).
beat_priority(kavi_eats_pc, 2).
beat_precondition(kavi_eats_pc,
		  $global_root/plot_points/ate/ $kavi/ $pc).
beat_monolog(kavi_eats_pc,
	     $kavi,
	     ["Sorry, old girl,",
	      "but I'm afraid I can't let you search my house.",
	      "I know it's horribly rude to eat you,",
	      "But you see, I don't have a gun.",
	      "So there's really no alternative."]).