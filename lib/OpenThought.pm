# This file is Copyright (c) 2000-2003 Eric Andreychek.  All rights reserved.
# For distribution terms, please see the included LICENSE file.
#
# $Id: OpenThought.pm,v 1.84 2003/04/28 04:28:29 andreychek Exp $
#

package OpenThought;

=head1 NAME

OpenThought - Web Application Engine

=head1 SYNOPSIS

 use OpenThought();

 my $o = OpenThought->new( $OP );

 my $field_data;
 $field_data->{'myTextBox'}    = "Text Box Data";
 $field_data->{'myCheckbox'}   = "true";
 $field_data->{'myRadioBtn'}   = "RadioBtnValue";
 $field_data->{'mySelectList'} = [
                                    [ "text1", "value1" ],
                                    [ "text2", "value2" ],
                                    [ "text3", "value3" ],
                                 ];

 my $html_data;
 $html_data->{'id_tagname'} = "New HTML Code";

 print $o->serialize({
            fields     => $field_data,
            html       => $html_data,
            focus      => "myTextBox",
            javascript => $javascript_code
 });

=head1 DESCRIPTION

OpenThought is a powerful and flexible web application environment.
OpenThought applications are different from other web applications in that all
communication between the browser and the server is performed in the
background.  This gives a browser the ability to receive data from the server
without ever reloading the currently loaded document.  Data received can be
displayed automatically on the existing page, can access JavaScript functions
and variables, and can load new pages.  Additionally, OpenThought completely
manages all of your session data for you.  These features give the look and
feel of a full-blown application instead of just an ordinary Web page.

OpenThought is extended with L<OpenPlugin|OpenPlugin> , also described briefly
in this documentation.

=head1 FUNCTIONS

=cut

use strict;

$OpenThought::VERSION="0.64";

# Include the OpenThought core components
use OpenThought::XML2Hash 0.55 ();
use OpenThought::Serializer();
use OpenThought::Template();

use OpenPlugin 0.10 ();


#/-------------------------------------------------------------------------
# function: new
#

=pod

=over 4

=item new

 $o = OpenThought->new( $OP, {
                Prefix          => "/path/which/overrides/config",
                OpenThoughtRoot => "/path/which/overrides/config",
             });

Creates a new OpenThought object.

=over 4

=item Parameters

=over 4

=item $OP

An OpenPlugin object.

=item Prefix (optional)

The directory prefix OpenThought Data Files were installed under.

The value for this is typically set in the OpenThought-httpd.conf file.
However, if you wish to override it, or you don't have the ability to edit that
file (ie, you don't have root on the webserver), you can set Prefix
here.

=item OpenThoughtRoot (optional)

The full path to the directory under which all OpenThought Applications will be
located.  Please include a trailing slash.

The value for this is typically set in the OpenThought-httpd.conf file.
However, if you wish to override it, or you don't have the ability to edit that
file (ie, you don't have root on the webserver), you can set OpenThoughtRoot
here.

=back

=item Return Value

=over 4

=item $o

OpenThought object.

=back

=back

=back

=cut

# The main OpenThought constructor
sub new {
    my ( $this, $op, $args ) = @_;

    if ( $args ) {
        if ( exists $args->{ Prefix } ) {
            $OpenThought::Prefix = $args->{ Prefix };
        }

        if ( exists $args->{ OpenThoughtRoot } ) {
            $OpenThought::OpenThoughtRoot = $args->{ OpenThoughtRoot };
        }

    }

    # If we don't have a Prefix set anywhere, try and figure it out from the
    # location of the config file passed in
    unless ( $OpenThought::Prefix ) {
        require File::Basename;
        my $dir = File::Basename::dirname( $op->config->{_m}{dir} );
        $dir =~ s/etc.$//;
        $OpenThought::Prefix = $dir;
    }
    my $class = ref( $this ) || $this;

    my $self = {
            OP  => $op,
    };

    return bless ($self, $class);
}


#/-------------------------------------------------------------------------
# function: settings
#

=pod

=over 4

=item settings

 $string = $o->settings({  autoclear         => boolean,
                           maxselectboxwidth => size,
                           fetchstart        => string,
                           fetchdisplay      => string,
                           fetchfinish       => string,
                           runmodeparam      => string,
                           order             => [ "fetchstart", "autoclear" ]
                        });

Alter settings in the currently running OpenThought application.  These
settings will persist, until otherwise altered.  To temporarily change
settings, these same options can be used in the serialize function.

=over 4

=item Parameters

=over 4

=item autoclear

The default behaviour for select lists is to clear themselves before data is
put into them.  Setting autoclear to a false value is one method of altering
that behaviour.  If autoclear is false, the contents of a select list are
preserved, and any new data is appended to the select list.  Any number less
then 1 and 'false' are considered false values, everything else is true.

When autoclear is set to false, you can still clear a select list by passing in
an empty string as a parameter to the select list.

=item maxselectboxwidth

Aside from Netscape 4, all browsers which receive text into a select box resize
that select box to the width of the longest entry.  Select box resizing is
neat, but sometimes it ends up being much to big, and can adversly affect other
parts of your visual layout.  This option allows you to modify the size of text
going into a SelectBox, so the browser doesn't make the select box too big.
Text going into a select box will be truncated if it is longer then the max
width set here.  This can be any number, or 0 to not constrain the size.

=item nullreply

If the server sends us a packet which contains no data at all, give this
message to the user in a popup box.

=item runmodeparam

The name of the parameter which holds the run mode.  The JavaScript in the
browser uses this when you send data the the server -- it figures out which run
mode you are trying to run, and sets the appropriate parameters, so
L<OpenPlugin::Application> can find it.  This, of course, doesn't matter if you
aren't using L<OpenPlugin::Application>.

=item order

As parameters are serialized and executed in a particular order, this parameter
allows you to override the default and specify exactly what this order will be.

This option is a reference to an array, containing the proper order for all the
items in the call.  Although this is more useful in the serialize function, it
still could be beneficial to alter the order of settings.  The current order
these are executed in are: autoclear, maxselectboxwidth, runmodeparam,
fetchstart, fetchdisplay, and fetchfinish.

=back

=item Return value

=over 4

=item $string

A string, which contains the settings to be given to the browser.  Often
this is just given directly to the browser by your application, although you
can modify it first if you desire.

=back

=back

=back

=cut

sub settings {
    my ( $self, $params ) = @_;

    my $serializer = OpenThought::Serializer->new({ OP => $self->{OP} });

    $serializer->params( $params );

    return $serializer->output;
}


#/-------------------------------------------------------------------------
# function: serialize
#

=pod

=over 4

=item serialize

 $string = $o->serialize({  fields     => $field_data,
                            html       => $html_data,
                            focus      => $field_name,
                            javascript => $javascript_code,
                            url        => $content_url,
                            setting    => $value,
                            order      => [ "javascript", "fields" ],
                        });

Serialize data that you wish to give to the browser.

=over 4

=item Parameters

=over 4

=item fields

A hash reference containing keys which map to HTML form element names in the
HTML document.  The value of each hash key will be displayed in the
corresponding field.

For radio buttons, the value for the hash key should be the value of the radio
button element in the HTML.  The radio button with the name and value which
matches the hash key and value will be the element that gets selected.

Select List elements are special cases.  Select Lists should have a hash key
with a reference to an array of arrays.

There are examples of these below.

=item html

A hash reference containing keys which map to HTML id attributes.  You can add
id tags to nearly any HTML attribute.  The value of each hash key will then be
displayed within the corresponding id attribute.  This effectively allows you
to replace any html currently loaded in the browser with whatever content you
desire, on the fly.

=item focus

A string containing the name of the field within the HTML code which you wish
to focus.

=item javascript

A string containing the JavaScript code you wish to run.  This will be run by
the browser, within your application's namespace.  You do not need to add
script tags.

=item url

The url parameter allows you to load a new html document, in the content frame.
All your base files which are loaded remain the same -- meaning your session
and such are preserved -- what changes is the user interface, when using this
option.  It first expires the cache associated with the form elements in the
existing page, and then loads the new page you requested.

=item setting

This is the same as calling the settings function, except that when used here,
the setting is only changed for this one call, and then it is restored to it's
previous value.  The keyword to use for this option is not the literal word
'setting', but any of the settings listed under the settings function.

=item order

Since parameters are serialized and executed in a particular order, this
parameter allows you to override the default and specify what this order will
be.  This is a reference to an array, containing the proper order for all the
items in the call.  The default order is:  settings (see settings function),
followed by fields, html, javascript, url, and focus.

=back

=item Return value

=over 4

=item $string

A string, which contains the serialized data to be given to the browser.  Often
this is just given directly to the browser by your application, although you
can modify it first if you desire.

=back

=back

=back

=cut

sub serialize {
    my ( $self, $params ) = @_;

    my $serializer = OpenThought::Serializer->new({
                                 save_settings => 1,
                                 OP            => $self->{OP},
                                });

    $serializer->params( $params );

    return $serializer->output;
}


#/-------------------------------------------------------------------------
# function: deserialize
#

=pod

=over 4

=item deserialize

 $hashref = $o->deserialize( OpenThought )

Retrieve the parameters sent to us during a typical OpenThought request.

=over 4

=item Parameters

=over 4

=item OpenThought

The parameter, passed to us from the browser, named 'OpenThought'.  This can be
retrieved using $self->OP->param->get_incoming( 'OpenThought' ).

=back

=item Return value

Deserialize returns a hash reference with the following keys:

=over 4

=item fields

A hash reference containing keys and values which map to the HTML form field
names and values we were sent from the browser.

=item expr

A hash reference containing keys/value pairs as sent to us by the
browser.  These are expressions which the application developer wanted sent to
the server upon a particular event.

=item session_id

A string containing the session id for your application.

=item run_mode

A string containing the current run mode.  The key C<run_mode> is the
C<run_mode_param>, as set in the config file, or overridden with the
C<settings()> or C<serialize()> functions.

=back

=back

=back

=cut

sub deserialize {
    my ( $self, $xml_param ) = @_;

    return undef if ( not $xml_param or $xml_param eq "1" );

    my $serializer = OpenThought::Serializer->new({ OP => $self->{OP} });

    my $params = $serializer->deserialize( $xml_param );

    return ({
        fields      => $params->{'fields'},
        expr        => $params->{'expr'},
        #session     => $self->{OP}->session->fetch(
        #                                    $params->{settings}{session_id} ),
        session_id  => $params->{'settings'}{'session_id'},
        $params->{'settings'}{'runmode_param'} =>
                                            $params->{'settings'}{'runmode'},
    });
}


#/-------------------------------------------------------------------------
# function: get_application_base
#

=pod

=over 4

=item get_application_base

 $string = $o->get_application_base( [ $url ] )

Retrieve the base files required for a browser to load an OpenThought
Application

=over 4

=item Parameters

=over 4

=item $url (optional)

If the url where the OpenThought HTML Content can be found is different from
the one the browser just requested, include it here.  Otherwise, it defaults to
using the current url.

=back

=item Return value

=over 4

=item $string

Returns as a string the html base code that is required in order for your
application to run.  Often this is just given directly to the browser by your
application, although you can modify it first if you desire.

=back

=back

=back

=cut

sub get_application_base {
    my ( $self, $url ) = @_;

    $url ||= $self->{OP}->request->uri;

    my $template = OpenThought::Template->new( $self->{OP}, $url );
    $template->retrieve_template();
    $template->insert_parameters();

    return $template->return_template();
}


1;

__END__

=head1 INTERACTING WITH THE BROWSER

=head2 Sending Data to the Browser

The following methods show you how you can send data from the server to the
browser.

B<Just a Hashref>

You only need a reference to a hash to send data to the browser.  If the
hashref containing all of our field data is called $field_data, then all we
need to do in our code is:

 # Send the outgoing HTTP Header
 $OP->httpheader->send_outgoing();

 # Populate the form fields and html with the data within our hashref
 print $o->serialize({ fields => $field_data, html => $html_data });

B<Populating Text, Password, and Textarea HTML Elements>

 $field_data->{'fieldname'} = "data";

B<Populating and Selecting Select List HTML Elements>

 $field_data->{'selectbox_name'} = [
                                        [ "Example 1", "value_one"   ],
                                        [ "Example 2", "value_two"   ],
                                        [ "Example 3", "value_three" ],
                                   ];

This will set the text of a select box to the left column above, and the value
of that text to the right column.

In the case that you don't have two columns worth of data you wish to use, you
can also do:

 $field_data->{'selectbox_name'} = [
                                     [ "Example 1"  ],
                                     [ "Example 2"  ],
                                     [ "Example 3"  ],
                                   ];

This makes both the text and value of the selectbox identical, and requires
sending less data to the browser (which, of course, saves bandwidth).

The above array of arrays will erase the current contents of the select list
with the data in the array.  To add a single line to the end of the select
list, you can use the following:

 $field_data->{'selectbox_name'} = [ "Example 1", "value_one" ];

And you can also use:

 $field_data->{'selectbox_name'} = [ "Example 1" ];

This will set both the text and value of the entry to "Example 1".

Also, if autoclear is set to false (not the default), you can use the following
to manually clear the contents of a select list:

 $field->{'selectbox_name'} = [ "" ];

To select (highlight) an item in an existing list of elements, you can send a
select list a single string like so:

 $field->{'selectbox_name'} = "optionvalue";

Which ever item in the select list has the value C<optionvalue> will become
highlighted.

For more information on how to add data to a select box without erasing the
current contents, be sure to check out the C<autoclear> setting.

B<Selecting Checkbox HTML Elements>

 $field_data->{'checkbox_name'} = "value";

To uncheck a checkbox, set value to any of:

=over 4

=over 4

=item * false | False | FALSE

=item * unchecked

=item * any number less then 1

=back

=back

Setting the value to anything other then the above will cause the checkbox
to be checked.

B<Selecting Radio Button HTML Elements>

 $field_data->{'radiobtn_name'} = "radiobtn_value";

radiobtn_value is the value in the "value=" tag of the radio button.

Radio buttons can only be selected, they cannot be directly unselected.  The
only way to unselect a radio button is to select a different radio button in
that group.

B<Updating Existing HTML Code>

 $html_data->{'id_tagname'} = "<h2>New HTML Code</h2>";

This inserts the code "<h2>New HTML Code</h2>" inside the tag with the id
attribute labeled 'id_tagname'.  This replaces any text or code that may have
originally existed within that tag.

Unlike updating form data, updating HTML currently only works in browsers which
support the 'innerHTML' method.  That includes IE 5.x, Netscape 6.x, and
Mozilla.

B<Focusing an Element>

You can give the focus to any form element within the browser simply by saying:

 $o->serialize({ focus => "fieldname" });

B<Running JavaScript>

You can easily send JavaScript to the browser, allowing you to call JavaScript
functions, access JavaScript variables, and even create new functions -- all
from the server.

The following calls the JavaScript 'alert' function:

 $o->serialize({ javascript => 'alert("Hello!");' });

The next example calls the hypothetical javascript function 'myfunction', using
param1 and param2 as arguments to that function:

 $o->serialize({ javascript => 'myfunction(param1, param2);' });

You can send any JavaScript you want, but make sure it's properly formated
code.  OpenThought does not validate whether or not your JavaScript syntax is
correct, the browser will be your judge!  If something isn't working, pull up
your browser's JavaScript console, it may provide you with some insight as to
what isn't working properly.  You do not need to include script tags.

B<Loading a New Page>

There are plenty of cases where it may be desirable load a new page, and to not
keep all your data on one particular page.  Loading a new page is quite simple,
and can be initiated from the server, or from the browser.

Here is an example of how you might tell the browser, from the server, to load
a new URL:

 $o->serialize({ url => '/OpenThought/newurl.pl' });

This function will have the browser call the perl script 'newurl.pl'.  It's
then up to newurl.pl to deliver some sort of content back to the browser.
Although you are loading a new page, the session is preserved across this call.

You may also load a new page from the browser when a user clicks a button or
link.  See the 'FetchHtml()' function in 'Sending Data to the Server' below.

B<Using DBI>

You can send the results of a database search directly to the browser, and have
the data from the results put into their respective fields.  You only need one
thing in order for this to work -- the field names in your database need
to match your field names in the HTML.  For example:

 my $sql = "SELECT name, address, phone, age, married " .
           "FROM sometable WHERE name="Tim Toady";

 my $sth = $dbh->prepare($sql);
 $sth->execute;

 $field_data = $sth->fetchrow_hashref;

In this case, lets say we have 'name', 'address', 'phone', and 'age' as
text fields in our HTML, and 'married' is a checkbox.  As soon as we send
$field_data to the browser, these fields (which must exist) will all be filled
in with the appropriate data.

This also works for select lists:

 my $sql = "SELECT name, ssn FROM sometable";

 my $sth = $dbh->prepare($sql);
 $sth->execute;

 $field_data->{'people'} = $sth->fetchall_arrayref;

This selects the name and social security number from everyone in the table,
and will allow us to use it to populate a select list named 'people'.

=head2 Sending Data to the Server

You can send data from the browser to the server anytime you want by simply
generating an event.  Events are often generated by clicking buttons or links.
JavaScript functions like onMouseOver, onClick, onChange, etc.. they can all
allow you to cash in on an event, and you can take advantage of them to send
data to the server at that time.

The two JavaScript functions available to you for communicating with the server
are B<CallUrl()> and B<FetchHtml()>.  Their usage and parameters are identical,
but they perform very different functions.  B<CallUrl()> sends data in the
background to the server, and the server can respond in the background with
it's own packet.  This function does not make the page reload.  The function
B<FetchHtml>, however, does reload the page.  It's sole purpose is to fetch
new HTML content for your content screen, replacing your existing content
with the content it is given.  This is a fancy way of saying it just loads a
new page.

The following are some examples of how you might use these two functions.  In
any of the following situations, the two functions are interchangable.  It all
just depends on what you want to happen.

B<Button Events>

 <input type="button" name="search" value="Click me!"
        onClick="parent.CallUrl('/OpenThought/servercode.pl',
                                'field1', 'field2', 'foo=bar');

Upon clicking this button, it will send the current contents of the fields
named 'field1' and 'field2' to /OpenThought/servercode.pl.  It will also send
the expression "foo=bar".  When this gets to the server, 'foo' will be a hash
key, 'bar' will be set to the value of that key.

Be careful using submit and image buttons.  You don't want your form to
actually perform a "submit", which causes the page to refresh.  You are merely
looking to "catch" the submit event, and perform an action when that submit
even is generated.  If you wish to use a submit or image button, you should
define your form like this:

 <form onSubmit="return false">

Now your browser can use submit and image buttons to send data to the server
without refreshing.

B<Using Links>

The following example shows you how you can use a typical HTML link to send
data to the server without causing the page to refresh:

 <a href="javascript:parent.CallUrl('/OpenThought/servercode.pl',
                                    'run_mode=forgot_password')">Click me!</a>

B<Select List Events>

 <select name=mySelectList size=10
         onChange="parent.CallUrl('/OpenThought/servercode.pl',
                                  'mySelectList')>

Whenever a new item in this select list is highlighted, it will send it's value
to /OpenThought/servercode.pl.

=head1 EXTENDED FUNCTIONALITY: OPENPLUGIN

Instead of building all OpenThought's functionality into the core OpenThought
modules, non-core functionality was split off into a reusable component called
L<OpenPlugin>.  OpenPlugin is a plugin manager which may be used in any web
application, including OpenThought.  The list of plugins if offers is
currently:

=over 4

=item * L<Application|OpenPlugin::Application>

=item * L<Authentication|OpenPlugin::Authentication>

=item * L<Cache|OpenPlugin::Cache>

=item * L<Config|OpenPlugin::Config>

=item * L<Cookie|OpenPlugin::Cookie>

=item * L<Datasource|OpenPlugin::Datasource>

=item * L<Exception|OpenPlugin::Exception>

=item * L<Httpheader|OpenPlugin::Httpheader>

=item * L<Log|OpenPlugin::Log>

=item * L<Param|OpenPlugin::Param>

=item * L<Request|OpenPlugin::Request>

=item * L<Session|OpenPlugin::Session>

=item * L<Upload|OpenPlugin::Upload>

=back

=head2 OpenPlugin Usage

Here you will see methods of how to use OpenPlugin within OpenThought.  For
more information on OpenPlugin, please see the L<OpenPlugin
documentation|OpenPlugin> included with the OpenPlugin distribution.

=over 4

=item Application

This is a powerful component which is a subclass of L<CGI::Application>.  It,
in the authors words, will "make it easier to create sophisticated, reusable
web-based applications".

While using OpenPlugin::Application isn't necessary, it's highly (very highly!) recommended.

=item Authenticate

Authenticate a user:

 $auth = $OP->authenticate->authenticate({ username => "some_username",
                                           password => "some_password",
                                        });

The variable $auth will be true if the user is successfully authenticated,
false otherwise.

=item Cache

If you wish to use a cache:

 $OP->cache->save( \%cache_data, {
                         id      => "Unique name for this cache entry",
                         expires => "+3h",
                 });

And then later, to retrieve the cache:

 my $cache = $OP->cache->fetch( "Unique name for this cache entry" );

$cache will be undef if there is no valid cache data for the id being given.

=item Cookie

A cookie can be sent to the browser with the following:

 $OP->cookie->set_outgoing({  name    => 'testcookie',
                              value   => 'My Cookie',
                              expires => '+1h',
                           });

To retrieve the cookies from the client request:

 my $cookies = $OP->cookie->get_incoming;

=item Datasource

After defining your datasource in the OpenThought config file, you can access
it via the OpenPlugin datasource interface.

 $dbh = eval { $OP->datasource->connect( "datasource_name" ); };
 if ( $@ ) {
     $@->throw("Connection Error: $@\n");
 }

At this point, $dbh is a typical DBI database handle, and may be used as such:

 my $sth = $dbh->prepare("SELECT * from somewhere");
 $sth->execute;
 my $rows = $sth->fetchrow_hashref;

Now you have the first row of data from your database search stored in $row.
See the DBI documentation for more information on interacting with databases
and their results.

=item Exception

You can use this to throw an exception:

 $OP->exception->throw( "Some Error Message" );

=item Httpheader

You can send a typical text/html header like so:

 $OP->httpheader->send_outgoing();

=item Logging

To log a message to the current logging facility:

 $OP->log->warn("My log message");

=item Parameter

To retrieve a parameter sent from the browser to the client:

 $OP->param->get_incoming("parameter_name");

=item Session

Retrieve your session:

After properly calling OpenThought's deserialize function, your session_id is
available as if it were a GET/POST parameter.  You can retrieve it like so:

 $session_id = $OP->param->get_incoming( 'session_id' );

And then you can recreate your session:

 $session = $OP->session->fetch( $session_id );

You may make any modifications you wish, and once again save this session by
saying:

 $session->{'key'} = "somevalue";
 $OP->session->save( $session );

You may want to perform the save *after* you've sent the headers and data back
to the browser if you are able to.  Saving the session isn't something that's
usually necessary before the browser is given it's information. Choosing to
save afterwards will get the data to the user faster.

=back

=head1 BACKGROUND

We often find outselves waiting around for webpages to load.  While a bit
painful, many have gotten used to this.  I haven't :-)

When going from one webpage to another, the amount of content that actually
changes is often minimal.  But if our browser has been told not to cache it --
which is often what happens with dynamic webpages -- we have to download again
everything we've already downloaded on the previous page.  As Jar Jar would
say, "How wude!"

One of OpenThought's major features is that it allows you to set up an entire
application using just one screen.  After a given user loads that screen,
they'll never have to load it again, for the life of that application.  Content
can be exchanged back and forth from the server and client, all without causing
that page to refresh or reload.  Upon receiving new content, OpenThought
dynamically displays it within your browser.

And OpenThought offers a lot more than this.  OpenThought can provide a full
environment for your applications.  It's not always practical to squeeze
screens upon screens of data into one page.   If you want to have several
pages, thats fine.  OpenThought provides you with an environment where session
data is maintained for you, across any number of pages.

OpenThought gives you an easy way of tieing together multiple web pages, and
allows you to build web applications which act like "real" applications.  When
an application is required, some people would decide to build it in Tk, Visual
Basic, gtk, or any number of other systems which offer a visual interface.  But
then, your application is either not available on the web, or you have to
create a seperate web interface to interact with the backend.  And this
seperate web interface no longer looks or acts like your application, it acts
like an ordinary webpage, requiring several screens to get the same amount of
content that your application offered in one.

By not ever needing to reload the page, OpenThought offers this application
look and feel that's been missing from the web.  This allows you to create just
one interface, for both LAN and web use.

=head1 HOW IT WORKS

An OpenThought Application is made up of three parts. There is the OpenThought
Engine, the OpenThought HTML Document, and the OpenThought Server Backend.  You
create the document and backend, the engine is provided for you.  All three
components are logically seperate, and never need to reside on the same
computer.

You just installed the first part, the OpenThought Engine, when you installed
this package.  The OpenThought Engine is already created for you, the most
you'll have to do with this is alter the config file.

The second part is the User Interface, known as the OpenThought HTML Document.
This component is created by you, the application developer.  The OpenThought
HTML Document is made up the HTML screens that you provide for the user to
interact with.  This is where you begin to notice the differences with
OpenThought applications.  Any given screen interacts with the server in the
background.  These screens don't need to submit, don't need to go away, don't
need to be refreshed.  Whenever you want data to be displayed for the user, it
can all be displayed dynamically.

The third part is the script on the server, known as the OpenThought Server
Backend.  This component is also developed by the application developer.  This
is the code sitting on the server that receives data sent to it by the user
interface.  Typically, this would be written in Perl.  However, the means are
available to write this in other languages.  While no such plugins currently
exist, eventually you will be capable of communicating with the OpenThought
Engine via SOAP, Jabber, and other such things.  Feel free to be adventurous
and write the plugin yourself :-)

The secret to how OpenThought functions are hidden HTML frames and some funky
JavaScript.  These are used to submit data to the server, and the server's
responses are also retrieved by these hidden frames.  When data is received
from the server, OpenThought's internal Javascript routines are used to
properly handle it -- whether it needs to be displayed, whether it should be
calling a JavaScript function, or any number of things.

Lets go step by step through a summary of what happens when using an
OpenThought Application to dynamically display data.

=over 4

=item 1. The browser requests your OpenThought Application.

=item 2. Your application gives the browser the HTML portion of your application.

=item 3. The user can now interact with this document.  As an example, lets say
that he entered a person's last name, and clicked a submit button.

=item 4. Instead of the OpenThought HTML Document being directly submitted as
one would typically expect, the data it wants to send to the server is first
converted to XML, and given to the hidden frame.  The packet of data is then
sent to the server via this hidden frame.  The HTML the user already has in
their browser is left completely in tact, and never reloaded or refreshed.

=item 5. The OpenThought Server Backend (which you developed) now receives the
data.  It doesn't need to know how to parse this data though, and uses the
OpenThought Engine to deserialize it.

=item 6. The OpenThought Engine deserializes the packet, and returns it to the
Application in the form of a hash (also sometimes called an associative array).

=item 7. The Application is now free to do whatever it wants with this
information.  To continue our example, if we were sent a last name, perhaps we
would do a search for this person's phone number in a database.

=item 8. After we put together a dataset we would like to send back to the
browser (a phone number in this case), we send it to the OpenThought Engine, in
the form of a hash, to be serialized into a packet.  For any data you wish to
have displayed, the hash key that you use would correspond to a form element
name in the OpenThought HTML Document.

=item 9. The OpenThought Engine gives us back a packet, and we can now send
this packet to the browser.

=item 10. After receiving this packet, the browser immedietly handles the
information for you -- and in this case, displays the phone number in the
appropriatly named field.  There is no programming on your part needed for this
to work, OpenThought's JavaScript routines figure this out for you based on
your hash keys as mentioned above.

=back

This entire process actually runs extremely fast, and certainly competes with
other types of applications.  I've seen round trip times as low as 26
milliseconds, which certainly beats the pants off loading an entire webpage
containing the same data :-)

=head1 GETTING STARTED

So far, this documentation has been all theory. But I know you're itching to
create you own application, so we'll get into the nitty gritty now :-)

=head2 Genesis of an OpenThought Application

From here on out, we are assuming that you have successfully installed
OpenThought, and that the demo program works correctly.  If this is not the
case, see the INSTALL file for instructions on getting OpenThought up and
running.

Now, pick a name for your application, and let's get to work!

=head2 Location Location Location

The first thing you need to do is pick a location for your application.  When
OpenThought was installed on your system, an "OpenThoughtRoot" was chosen.
OpenThoughtRoot is a directory under which all your OpenThought application
executables (.pl files) need to be located.  It is recommented that you keep
your modules (.pm files) in a location not under your document root.  On my
RedHat system, I often use:

 # For .pl files
 /var/www/html/OpenThought/appname

 # For .pm files
 /var/www/site/App/Appname

So pick a spot for these files that works for you, and we're well on our way!

=head2 Create your User Interface

Next, create an HTML Document which will be your user interface.  You can put
this code anywhere you want, but I often use:

 # HTML Templates
 /var/www/site/templates/Appname

If you're into HTML, you'll like this part.  If not.. well, it doesn't have to
be too painful :-)  You could even use applications like Macromedia's
DreamWeaver and Fireworks to handle this visual design for you.

So, imagine all the things you would like to make available to your users, and
start coding.  You can use any number of form elements in your application.
Also, you can use multiple div tags in conjunction with CSS visible / hide to
give the look and feel of having tabs. With this, you can squeeze much more
data into your application.  However, implementing tabs does require a certain
amount of HTML / CSS / Javascript knowledge.. if you aren't up on that, there's
plenty of books, and even online tutorials on that subject.  This is also where
DreamWeaver and Fireworks can help you.

While developing your HTML code, you must give each of your form elements a
unique name.  For an example interface, feel free to use the demo-template.html
included with OpenThought.

Now, you may start wondering, "How do I submit data from these forms to the
server"?  Data is sent after some sort of event is generated... such as
clicking a button.  When such an event occurs, you'll want to call one of the
following Javascript functions:

 parent.CallUrl('application_url', form_element1, form_element2, ...)
   -- or --
 parent.FetchHtml('application_url', form_element1, form_element2, ...)

These functions get everything started.

See the section B<Sending Data to the Server> for more information on the above
two functions.

The parameter "application_url" is url of the application which will be
receiving this data.  An example of this is could be
"http://www.foo.com/OpenThought/applications/demo.pl", or even just
"/OpenThought/applications/demo.pl".

The parameters "form_element" allow you to send the contents of any number of
form elements to the server.  Simply list their names here.  You defined their
name when you used the <input name="foo"> attribute in your HTML.  This tag's
name is foo.  At the time the event is generated, the current values of these
elements will be taken, and it will all be sent to the server for you to
process.

In addition to being able to send form elements to the server, you can also
send an expression.  To do so, in place of passing a fieldname as an
argument, you can use 'foo=bar' as a parameter.  Don't use spaces, and make
sure you have it in quotes.

After that, your HTML is complete.

=head2 Create Your Server Backend

There are three phases of an OpenThought application, that your code needs to
be able to handle.  They can all be determined, simply by looking at what
parameters your script was passed.

=over 4

=item Phase 1. No Parameters

In the case that no parameters where sent to us, that means we're in the first
phase.  The browser is looking for us to give it the OpenThought base files,
which can be done with:

 print $o->get_application_base();

This retrieves the base files from the OpenThought Engine, and sends them to
the browser.

=item Phase 2. Parameter: OpenThought eq "1"

If you where sent the OpenThought parameter, and it's set to "1", the
browser is looking for your OpenThought HTML Document.  It's completely up to
you on how to handle this, but I personally like to use
OpenPlugin::Application's load_tmpl (which internally uses HTML::Template, and
returns an HTML::Template object):

 if ( $OP->param->get_incoming( "OpenThought" ) eq "1" ) {
     my $template = $self->load_tmpl( 'templates/demo-template.html' );

     print $template->output;
 }

=item Phase 3. Parameter: OpenThought

If you are sent the OpenThought parameter, and it's contents are an XML packet,
this means that the OpenThought application has finished loading, and that the
user has sent us some data.  All we need to do is process the data we were
sent, and respond in an appropriate manner.  For example:

 if(( $OP->param->get_incoming("OpenThought") &&
      $OP->param->get_incoming("OpenThought") ne "1" )) {

     $OP->param->set_incoming = $o->deserialize(
            $OP->param->get_incoming("OpenThought") );

     my $field_data;

     # If we were sent the parameter foo
     if ( $OP->param->get_incoming('fields')->{'foo'}) {
         $field_data->{comments} = "Thank you for sending foo!";
     }
     else {
         $field_data->{comments} = "Next time, send some foo!";
     }

     return $self->param('OpenThought')->serialize({ fields => $field_data });
 }

=back

Phase 1 and 2 are often short, simple, and straightforward.  The third phase is
typically where most of your coding will be.

Now that you know all this, you can breathe a sigh of relief, because you won't
have to deal with it much at all.  With the addition of
OpenPlugin::Application, and the usage of run modes, you won't typically need
to perform checks to figure out which phase of OpenThought you are in.  You'll
simply know what to deliver to the browser when it asks to run a given run
mode.

Now you can go ahead and write the code on the server end for your application.

It is highly  recommended (but not necessary) that you use
OpenPlugin::Application to build your application code.
OpenPlugin::Application is strikingly similar to CGI::Application (okay, okay,
so I just took CGI::Application, and changed every reference from CGI to
OpenPlugin :-).  It's very easy to understand, and the demo app that comes with
OpenThought does use OpenPlugin::Application.

The following are some examples of things you may want to do in OpenThought.

This is an example of how you would send data to a select list in your user
interface:

     $field_data->{'selectlist'} = [
                                     ['AIX'     ,'aix'    ],
                                     ['BeOS'    ,'beos'   ],
                                     ['Emacs'   ,'emacs'  ],
                                     ['HP_UX'   ,'hpux'   ],
                                     ['Linux'   ,'linux'  ],
                                     ['Netware' ,'netware'],
                                     ['OS/2'    ,'os2'    ],
                                     ['Plan 9'  ,'plan9'  ],
                                     ['Solaris' ,'solaris'],
                                     ['Windows' ,'windows'],
                                   ];


The hash key 'selectlist' is the name of the select element in the HTML
document of the demo application, included with the OpenThought distribution.
You then see two columns of data.  The data on the left side is what is
displayed in the select list, and the data on the right is the value assigned
to that text.  Said another way, the user with their web browser will see the
data on the left.  But when they click it, it's the data on the right which
will be sent to your code on the webserver.  For the technically inclined, the
name of this data structure is a hash of arrays of arrays.  For the not so
technically inclined, just make sure you use the correct amount of brackets :-)

To send data to HTML elements other then select lists:

 $field_data->{'os'}          = "Linux";
 $field_data->{'creator'}     = "Linus Torvalds";
 $field_data->{'notes'}       = "World Domination 2001";
 $field_data->{'free'}        = "true";
 $field_data->{'cool'}        = "true";
 $field_data->{'goodlooking'} = "true";

This is just a simple hash reference.  The key to the hash maps to a form field
name in the HTML Document.  Then whenever you send $field_data to the browser,
the form field with the name 'os' will display the text 'Linux', the form field
named 'creator' will display 'Linus Torvalds', etc.

You'll remember (from the demo app) that the last three elements we're dealing
with here are each checkboxes.  Checkboxes that are assigned the value "true"
become checked when we send this data to the browser.

Now, to define data and have it sent to your browser, you could say something
like:

 $field_data->{'os'}          = "Linux";
 $field_data->{'creator'}     = "Linus Torvalds";
 $field_data->{'notes'}       = "World Domination 2001";
 $field_data->{'free'}        = "true";
 $field_data->{'cool'}        = "true";
 $field_data->{'goodlooking'} = "true";

 return $self->param('OpenThought')->serialize({ fields => $field_data,
                                                 focus  => "selectlist" });

This will populate the fields in the HTML with the data you have in the
$field_data hash reference, and will focus the element "selectlist".

The above code samples are all taken from the demo application which comes with
OpenThought, named demo.pl.  Feel free to take a look at it for a complete
example of an OpenThought Application.

=head1 EXAMPLES

Continuing our use of OpenPlugin::Application, here are some examples of how
you might build an OpenThought application.  Some of these examples are
borrowed from the demo application.  Take a look at the demo app if you'd like
more information.

=head2 The .pl File (mod_perl)

Creating your .pl file is simple.  Just put it in your OpenThoughtRoot
Directory.  The file could contain something like:

 #!/usr/bin/perl -wT

 use strict;
 use lib "/path/to/pm/files";
 use Example();

 my $r = shift;

 my $example = Example->new( request => { apache => $r } );

 $example->run();

As for the "/path/to/pm/files" above, I often use /var/www/site for site
specific pm files.

=head2 The .pm File (mod_perl)

The .pm files will contain the meat of your application.  When using
OpenPlugin::Application, there are several subroutines you'll need to have,
which we'll go through.  For more information, please see
L<OpenPlugin::Application|OpenPlugin::Application> and the demo application.

 package Example;

 use strict;
 use base 'OpenPlugin::Application';
 use OpenThought();

 # Set up the run modes
 sub setup {
     my $self = shift;

     $self->run_modes(
            'mode1' => 'init_example',
            'mode2' => 'text_example',
            'mode3' => 'selectbox_example',
            'mode4' => 'radiobtn_example',
            'mode5' => 'html_example',
     );

     $self->start_mode('mode1');
     $self->mode_param('run_mode');
 }

 # Somewhat of a constructor -- called before setup()
 sub cgiapp_init {
    my $self = shift;
    my $OP   = $self->OP;

    $self->param( 'OpenThought' => OpenThought->new( $OP ));
    $OP->param->set_incoming(
                 $self->param('OpenThought')->deserialize(
                         $OP->param->get_incoming('OpenThought')));

    my $session = $OP->session->fetch(
                    $OP->param->get_incoming( 'session_id' ));

    $self->param( 'session' => $session );
 }

 # The default run mode
 sub init_example {
    my $self = shift;

    if( $OP->param->get_incoming('OpenThought')) {
        my $template = $self->load_tmpl('/path/to/demo-template.html');
        return $template->output;
    }

    else {
        return $self->param('OpenThought')->get_application_base();
    }
 }

=head2 OpenThought and CGI

Some users may find themselves needing to use CGI instead of mod_perl.  This
often will be because you don't have root on the machine, but I'm sure there
are other reasons someone will be able to come up with :-)

Be forewarned that CGI does run slower then mod_perl.  It might even be
possible to install your own version of Apache / mod_perl in your user space on
your ISP.  If this still doesn't appeal to you though, the following will
contain some examples on how to use OpenThought with CGI.

Using OpenThought under CGI very simple, you just have to be a bit more
explicit about some things.

Assuming you currently have a .pl with the following line (taken from the above
examples):

 my $example = Example->new( request => { apache => $r } );

You'll want to change it to read:

 my $example = Example->new( config => { src => "/path/to/OpenThought.conf" } );

There are two things that we just changed.  We stopped passing $r to the
Request plugin, and we put the path to the config file in there.  The $r
variable is only necessary when running under mod_perl.  We definitely want to
take that out when not using mod_perl.  As for the config file path -- under
mod_perl, we can state the path to the config file in the
OpenThought-httpd.conf file.  Under standard CGI, that won't work the way we
want it to, so we need to explicitely pass the config file location in.

You also have the line in your .pm file:

 $self->param( 'OpenThought' => OpenThought->new( $OP ));

Change to:

 $self->param( 'OpenThought' => OpenThought->new( $OP,
                        { Prefix => '/path/to/prefix/dir' }));

This modification is again necessary under CGI.  When using mod_perl, the
Prefix is set in the OpenThought-httpd.conf file.  Under CGI, you won't be able
to use that file, so you'll need to exlicitely pass in the path when initiating
your OpenThought object.

=head2 Text, Password, and Textarea HTML Elements

Client:

    <form name="myForm">

    <input type=text name=textbox_example>
    <input type=button name=search value='Click me!'
       onClick="parent.CallUrl( '/OpenThought/demo_app/text.pl',
                                'run_mode=mode2', 'textbox_example')">
    </form>


Server:

 sub text_example {
    my $self = shift;
    my $OP   = $self->OP;

    my $param = $OP->param->get_incoming('fields')->{'textbox_example'}";
    warn "We were sent $param";

    my $field_data;
    $field_data->{'textbox_example'} = "Blah blah blah";

    return $self->param('OpenThought')->serialize({ fields => $field_data });
 }

=head2  Selectbox HTML Elements

Client:

    <form name="myForm">

    <select name=selectbox_example>
        <option value="test">Test!
    </select>

    <input type=button name=search value='Click me!'
       onClick="parent.CallUrl( '/OpenThought/demo_app/selectbox.pl',
                                'selectbox_example')">
    </form>

Server:

 sub selectbox_example {
    my $self = shift;
    my $OP   = $self->OP;

    my $param = $OP->param->get_incoming('fields')->{'selectbox_example'}";
    warn "We were sent $param";

    my $field_data
    $field_data->{'selectbox_example'} = [
                                           [ "Example 1", "ex_one"   ],
                                           [ "Example 2", "ex_two"   ],
                                           [ "Example 3", "ex_three" ],
                                         ];

    return $self->param('OpenThought')->serialize({ fields => $field_data });
 }


=head2  Radio Button HTML Elements

Client:

    <form name="myForm">

    <input type=radio name=radio_example value="ex_one" checked><br>
    <input type=radio name=radio_example value="ex_two"><br>
    <input type=radio name=radio_example value="ex_three"><br>
    <input type=radio name=radio_example value="ex_four"><br>

    <input type=button name=search value='Click me!'
       onClick="parent.CallUrl( '/OpenThought/demo_app/radio.pl',
                                'radiobox_example')">
    </form>

Server:

 sub radiobtn_example {
    my $self = shift;
    my $OP   = $self->OP;

    my $param = $OP->param->get_incoming('fields')->{'radiobtn_example'}";
    warn "We were sent $param";

    my $field_data;
    $field_data->{'radio_example'} = "ex_one";

    return $self->param('OpenThought')->serialize({ fields => $field_data });
 }

=head2  Checkbox HTML Elements

Client:

    <form name="myForm">

    <input type=text name=checkbox_example>
    <input type=button name=search value='Click me!'
       onClick="parent.CallUrl( '/OpenThought/demo_app/checkbox.pl',
                                'checkbox_example')">
    </form>


Server:

 sub checkbox_example {
    my $self = shift;
    my $OP   = $self->OP;

    my $param = $OP->param->get_incoming('fields')->{'checkbox_example'}";
    warn "We were sent $param";

    my $field_data;
    $field_data->{'checkbox_example'} = "true";

    return $self->param('OpenThought')->serialize({ fields => $field_data });
}

=head2  HTML Example

Client:

    <h2>
      <div id="html_example">Old HTML</div>
    </h2>
     onClick="parent.CallUrl( '/OpenThought/demo_app/html.pl')">


Server:

 sub html_example {
    my $self = shift;

    my $html_data;
    $html_data->{'html_example'} = "New HTML";

    return $self->param('OpenThought')->serialize({ html => $html_data });
}

=head1 AUTHOR

Eric Andreychek (eric at openthought.net)

=head1 COPYRIGHT

The OpenThought Application Environment is Copyright (c) 2000-2003 by Eric
Andreychek.

The OpenThought Application Environment is licensed under the GNU Public
License (GPL).

=head1 BUGS

Certain JavaScript functions don't seem to work properly under Internet
Explorer 5.0.  They work fine under 4.0, and fine under 5.5.  I'm working to
see if there is something that can be done about that.

Aside from that, bug hunting season has been good.  All known bugs have been
eradicated.  If you happen to run across one, please let me know and I'd be
more then happy to take care of it.  But real hackers would send a patch ;-)

=head1 SEE ALSO

L<OpenPlugin|OpenPlugin>

L<CGI::Application|CGI::Application>

L<Apache::Request|Apache::Request>

L<HTML::Template|HTML::Template>

L<OpenThought::XML2Hash|OpenThought::XML2Hash>

=head1 OPENTHOUGHT CONTRIBUTORS

* Greg Pomerantz (gmp216 at nyu.edu) - Put all sorts of time into that crazy
bug which made Apache segfault on every request. It ended up being a problem
with Apache and expat. Thanks to Greg for figuring that out!


