has_property(human, given_name).
has_property(human, surname).
has_property(human, gender).
has_property(human, job).

has_relation(human, knows_about).
has_relation(human, interested_in).
has_relation(human, member_of).
has_relation(human, friend_of).
has_relation(human, likes).
has_relation(human, loves).

implies_relation(interested_in, knows_about).
implies_relation(loves, friend_of).
implies_relation(friend_of, likes).