% Monitor goals quickly
/parameters/poll_time:3.

$global::fkey_command(alt-z, "Display captive's status") :-
   generate_character_debug_overlay($captive).
