#!/usr/bin/perl -wT

$ENV{PATH} = '/bin:/usr/bin:/usr/local/bin';
delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};

use strict;
use lib ".";


######################################
# CGI INSTALL
#
# Uncomment the following lines for a CGI installation
# Be sure to set "src" to point to your correct OpenThought.conf file

#require Demo;
#my $demo = Demo->new( PARAMS => {
#                    config  => { src => "/path/to/OpenThought.conf" },  });
#$demo->run();

######################################
# MOD_PERL 1.x INSTALL
#
# Uncomment the following lines for a mod_perl 1.x installation

require Demo;
my $r = shift;
my $demo = Demo->new( PARAMS => { request => { apache => $r }});
$demo->run();

######################################
# MOD_PERL 2.x INSTALL
#
# Uncomment the following lines for a mod_perl 2.x installation
#
# This section requires more code than the above 2 sections, only because
# mod_perl 2.x can't resolve the path to ".", so we have to determine what the
# current directory is.  In your scripts, you could just use absolute paths,
# and manually add your paths to @INC.

#use File::Basename;
#$Demo::modperl2_path = File::Basename::dirname( $ENV{SCRIPT_FILENAME} );
#($Demo::modperl2_path) =
#        $Demo::modperl2_path =~ m/(.*)/ if -d $Demo::modperl2_path;
#push @INC, $Demo::modperl2_path;
#require Demo;
#my $r = shift;
#my $demo = Demo->new( PARAMS => { request => { apache2 => $r }});
#$demo->run();

