#!/usr/bin/perl

# $Id: 02_serialize.t,v 1.1 2002/07/07 17:49:55 andreychek Exp $

use strict;
use Test::More  tests => 3;
use lib ".";
use lib "./t";
use OpenThoughtTests();

my $field_data = {
    stooge1  => "Larry",
    stooge2  => "Moe",
    stooge3  => "Curly",
};

my $o = OpenThought->new({ OpenThoughtData => "openthought/" });
my $ser_fields     = $o->serialize({ fields     => $field_data          });
my $ser_focus      = $o->serialize({ focus      => "stooge1"            });
my $ser_javascript = $o->serialize({ javascript => "alert('nyayaya');"  });

ok ( $ser_fields eq q{<script>Packet = new Object;Packet["stooge1"]="Larry";Packet["stooge2"]="Moe";Packet["stooge3"]="Curly";parent.OpenThoughtUpdate(Packet);</script>},
    "Field Serialization" );

ok ( $ser_focus eq q{<script>parent.FocusField('stooge1');</script>},
    "Focus Serialization" );

ok ( $ser_javascript eq q{<script>parent.frames[0].alert('nyayaya');</script>},
    "JavaScript Serialization" );
