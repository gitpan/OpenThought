# Makefile.PL for OpenThought                            http://openthought.net
# ---------------------------                           eric at openthought.net

use lib "inc";
use File::NCopy();
use File::Copy();
use File::Path;
use ExtUtils::MakeMaker qw(prompt);

eval "use 5.005_03";
if( $@ ) {
    print <<EOT;

 =============================================================
   Perl version 5.005_03 or later is required for OpenPlugin.
   Unfortunatly, you'll need to upgrade in order for it
   to work.  Try installing a new version of Perl to see
   what you're missing :-)
 =============================================================

EOT

   die "Perl version too old, quiting...\n";
}


use ExtUtils::AutoInstall (
   -version     => '0.30',
   -config      => {
       force    => 0,
   },
   -core        => [
      'Test::Harness'         => '2.0',
      'Test::More'            => '0.47',
      'File::Spec'            => '0.82',
      'HTML::Template'        => '2.2',
      'OpenThought::XML2Hash' => '0.56',
      'OpenPlugin'            => '0.10',
   ],
);

config_openthought();

WriteMakefile(
    AUTHOR        => 'Eric Andreychek (eric at openthought.net)',
    ABSTRACT      => 'OpenThought Web Application Environment',
    NAME          => 'OpenThought',
    DISTNAME      => 'OpenThought',
    VERSION_FROM  => 'lib/OpenThought.pm',
);


sub config_openthought {
    unless (prompt("\nCan I install some data files now?", 'Y/n') =~ /^y/i) {
        print "Warning: skipping data file installation.\n";
        print "Installation will be incomplete!\n\n";
        return;
    }

    my $OpenThoughtRoot = prompt("\n\n1. OpenThoughtRoot\n\n"                .
                                 "Directory, within Apache's DocumentRoot, " .
                                 "where you would like OpenThought\n"        .
                                 "Application .pl files to reside.\n\n",
                                 "/var/www/html/OpenThought");

    chomp $OpenThoughtRoot;

    my $OpenThoughtPrefix = prompt("\n2. Prefix\n\n"                         .
                                 "Directory prefix under which you would "   .
                                 "like to store OpenThought's data files.\n" .
                                 "This includes the config file, some "      .
                                 "templates, and that sort of thing.\n\n",
                                 "/usr/local");

    chomp $OpenThoughtPrefix;

    unless ( -d $OpenThoughtRoot ) {
        mkdir $OpenThoughtRoot, 0777  or die
            "Cannot create $OpenThoughtRoot: $!";
    }

    unless ( -d "$OpenThoughtRoot/demo_app" ) {
        mkdir "$OpenThoughtRoot/demo_app", 0777 or die
                                "Cannot create '$OpenThoughtRoot/demo_app': $!";
    }

    unless ( -d $OpenThoughtPrefix ) {
        mkdir $OpenThoughtPrefix, 0777 or die
            "Cannot create $OpenThoughtPrefix: $!";
    }

   my $file = File::NCopy->new(recursive => 1);
   $file->copy("demo_app/*", "$OpenThoughtRoot/demo_app") or die
    "Cannot copy demo application to $OpenThoughtRoot/demo_app: $!";

   if (-f "$OpenThoughtPrefix/etc/OpenThought.conf") {
      my $time = time();
      File::Copy::copy("$OpenThoughtPrefix/etc/OpenThought.conf",
                       "$OpenThoughtPrefix/etc/OpenThought.conf.$time") or die
                            "Cannot backup config file: $!";

      print "Found existing OpenThought.conf file.  Backing up to OpenThought.conf.$time\n";
   }

    my $file = File::NCopy->new(recursive => 1);
    $file->copy("openthought/*", $OpenThoughtPrefix) or die
        "Cannot copy data files to $OpenThoughtPrefix: $!";

   #my $httpdconf_path = prompt("\n3. In the file ${OpenThoughtData}/httpd-openthought.conf are some Apache\nsettings to make OpenThought work properly.  This file needs to be included\nfrom your httpd.conf.  I need the path to your httpd.conf to add the proper\ninclude line, or enter 0 to skip this step and you can do it later yourself.\n", "/etc/httpd/conf/httpd.conf");
   #chomp $httpdconf_path;

   #open(HTTPD_CONF, ">>$httpdconf_path") or die "Can't open $httpdconf_path!";
   #print HTTPD_CONF "Include ${OpenThoughtData}/httpd-openthought.conf";
   #close(HTTPD_CONF);
    print "\nFinished copying.\n";
    print "Please add the following line to the end of your httpd.conf if you're using mod_perl:\n";
    print "\n  Include ${OpenThoughtPrefix}/etc/OpenThought-httpd.conf\n\n";

}
