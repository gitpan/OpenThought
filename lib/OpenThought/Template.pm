# This file is Copyright (c) 2000-2002 Eric Andreychek.  All rights reserved.
# For distribution terms, please see the included LICENSE file.
#
# $Id: Template.pm,v 1.17 2002/10/23 01:55:09 andreychek Exp $
#

package OpenThought::Template;

use strict;
use HTML::Template();

$OpenThought::Template::VERSION = sprintf("%d.%02d", q$Revision: 1.17 $ =~ /(\d+)\.(\d+)/);

# Template constructor
sub new {
   my ($this, $op, $url) = @_;

   my $class = ref( $this ) || $this;

   my $self = {
         OP            => $op,
         url           => $url,  # URL where the find the HTML Content
         params        => "",    # Parameters to put in the template
         template_obj  => "",    # HTML::Template object
   };

   bless ($self, $class);

return $self;
}

# Pulls the template off the disk
sub retrieve_template {

   my $self = shift;

      eval {
         $self->{template_obj} = new HTML::Template(
            filename => "index-template.html",
            path     => [ "$OpenThought::Prefix/share/OpenThought/templates" ],
         );
      };
      if ($@) {
         $self->{OP}->exception->throw( "Error creating HTML Template Object!: $@" );
      }
}

# Inserts generated parameters into the template
sub insert_parameters {

   my $self = shift;

   $self->{params} = $self->gen_template_params();

   $self->{template_obj}->param($self->{params});
}

# Uses the template module to display the template
sub return_template
{
   my $self = shift;

# Call the output method of the html::template object
return $self->{template_obj}->output;
}

# Figures out the all the parameters for a particular template
sub gen_template_params {

   my $self = shift;

   my $template_params = {
      session_id          => $self->{OP}->session->create(),
      wrong_browser       => $self->_escape_javascript_text(
                               $self->{OP}->config->get('options', 'wrong_browser')),
      max_selectbox_width => $self->{OP}->config->get('options', 'max_selectbox_width'),
      fetch_start         => $self->{OP}->config->get('options', 'fetch_start'),
      fetch_display       => $self->{OP}->config->get('options', 'fetch_display'),
      fetch_finish        => $self->{OP}->config->get('options', 'fetch_finish'),
      run_mode_param      => $self->{OP}->config->get('options', 'run_mode_param'),
      application_url     => $self->{url},
   };

return $template_params;
}

# Don't allow any odd characters to jam up the javascript parsing
sub _escape_javascript_text {
    my ($self, $text) = @_;

    if ( $text ) {

        # Escape quotes
        $text =~ s/"/\"/g;

        # Okay, I don't understand how or why this works one bit, but what
        # we're doing is taking the text \n and changing it to \\n
        $text =~ s/\\n/\\n/g;
    }

return $text;
}

1;
