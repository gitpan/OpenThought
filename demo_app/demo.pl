#!/usr/bin/perl -wT

$ENV{PATH} = '/bin:/usr/bin:/usr/local/bin';
delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};

use strict;
use lib ".";
use Demo();


######################################
# MOD_PERL INSTALL
#
# Uncomment the following 3 lines for a mod_perl installation

my $r = shift;
my $demo = Demo->new( PARAMS => { request => { apache => $r }});
$demo->run();


######################################
# CGI INSTALL
#
# Uncomment the following 3 lines for a CGI installation
# Be sure to set "src" to point to your correct OpenThought.conf file

#my $demo = Demo->new( PARAMS => {
#                    config  => { src => "/path/to/OpenThought.conf" },  });
#$demo->run();

