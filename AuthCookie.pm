package Apache::AuthCookie;
use strict;
use mod_perl qw(1.07 StackedHandlers MethodHandlers Authen Authz);
use Apache::Constants qw(:common M_GET M_POST AUTH_REQUIRED REDIRECT);
use vars qw($VERSION);

# $Id: AuthCookie.pm,v 1.2 2000-01-27 22:07:13 ken Exp $
$VERSION = 2.0;

sub recognize_user ($$) {
  my ($self, $r) = @_;
  my $debug = $r->dir_config("AuthCookieDebug") || 0;
  my ($auth_type, $auth_name) = ($r->auth_type, $r->auth_name);
  return unless $auth_type && $auth_name;
  return unless $r->header_in('Cookie');

  my ($cookie) = $r->header_in('Cookie') =~ /${auth_type}_${auth_name}=([^;]+)/;
  $r->log_error("cookie ${auth_type}_${auth_name} is $cookie") if $debug >= 2;
  if (my ($user) = $auth_type->authen_ses_key($r, $cookie)) {
    $r->log_error("user is $user") if $debug >= 2;
    $r->connection->user($user);
  }
}


sub login ($$) {
  my ($self, $r) = @_;
  my $debug = $r->dir_config("AuthCookieDebug") || 0;

  my ($auth_type, $auth_name) = ($r->auth_type, $r->auth_name);
  my %args = $r->args;
  unless (exists $args{'destination'}) {
    $r->log_error("No key 'destination' found in posted data");
    return SERVER_ERROR;
  }
  
  # Get the credentials from the data posted by the client
  my @credentials;
  while (exists $args{"credential_" . ($#credentials + 1)}) {
    $r->log_error("credential_" . ($#credentials + 1) . " " .
		  $args{"credential_" . ($#credentials + 1)}) if ($debug >= 2);
    push(@credentials, $args{"credential_" . ($#credentials + 1)});
  }
  
  # Exchange the credentials for a session key.
  my $ses_key = $self->authen_cred($r, @credentials);
  $r->log_error("ses_key " . $ses_key) if ($debug >= 2);

  # Send the Set-Cookie header.
  my $cookie_path = $r->dir_config($auth_name . "Path");
  $r->err_header_out("Set-Cookie" => "${auth_type}_${auth_name}=$ses_key; path=$cookie_path");

  $r->no_cache(1);
  $r->err_header_out("Pragma" => "no-cache");
  $r->header_out("Location" => $args{'destination'});
  return REDIRECT;
}

sub identify ($$) {
  my ($auth_type, $r) = @_;
  my ($ses_key_cookie, $authen_script, $auth_user, $ses_key);
  my $debug = $r->dir_config("AuthCookieDebug") || 0;
  
  $r->log_error("auth_type " . $auth_type) if ($debug >= 3);
  return OK unless $r->is_initial_req; # Only authenticate the first internal request
  
  if ($r->auth_type ne $auth_type) {
    # This location requires authentication because we are being called,
    # but we don't handle this AuthType.
    $r->log_error($auth_type . "::Auth:authen auth type is " .
		  $r->auth_type) if ($debug >= 3);
    return DECLINED;
  }

  # Ok, the AuthType is $auth_type which we handle, what's the authentication
  # realm's name?
  my $auth_name = $r->auth_name;
  $r->log_error("auth_name " . $auth_name) if $debug >= 2;
  unless ($auth_name) {
    $r->log_reason("AuthName not set, AuthType=$auth_type", $r->uri);
    return SERVER_ERROR;
  }

  # There should also be a PerlSetVar directive that give us the path
  # to set in Set-Cookie header for this realm.
  my $cookie_path = $r->dir_config($auth_name . "Path");
  unless ($cookie_path) {
    $r->log_reason("Cookie path ($auth_name\Path) not set, AuthType=$auth_type", $r->uri);
    return SERVER_ERROR;
  }


  # Get the Cookie header. If there is a session key for this realm, strip
  # off everything but the value of the cookie.
  my ($ses_key_cookie) = ($r->header_in("Cookie") || "") =~ /$auth_type\_$auth_name=([^;]+)/;
  $ses_key_cookie = "" unless defined($ses_key_cookie);

  $r->log_error("ses_key_cookie " . $ses_key_cookie) if ($debug >= 1);
  $r->log_error("cookie_path " . $cookie_path) if ($debug >= 2);
  $r->log_error("uri " . $r->uri) if ($debug >= 2);

  if ($ses_key_cookie) {
    if ($auth_user = $auth_type->authen_ses_key($r, $ses_key_cookie)) {
      # We have a valid session key, so we return with an OK value.
      # Tell the rest of Apache what the authentication method and
      # user is.

      $r->no_cache(1);
      $r->err_header_out("Pragma", "no-cache");
      $r->connection->auth_type($auth_type);
      $r->connection->user($auth_user);
      $r->log_error("user authenticated as $auth_user")	if $debug >= 1;
      return OK;
    } else {
      # There was a session key set, but it's invalid for some reason. So,
      # remove it from the client now so when the credential data is posted
      # we act just like it's a new session starting.
      
      $r->err_header_out("Set-Cookie" => 
			 "$auth_type\_$auth_name=; path=$cookie_path; expires=Mon, 21-May-1971 00:00:00 GMT");
      $r->log_error("set_cookie " . $r->err_header_out("Set-Cookie"))
	if $debug >= 2;
    }
  }

  # They aren't authenticated, and they tried to get a protected
  # document. Send them the authen form.  There should be a
  # PerlSetVar directive that give us the name and location of the
  # script to execute for the authen page.
  
  unless ($authen_script = $r->dir_config($auth_name . "LoginScript")) {
    $r->log_reason($auth_type . 
		   "::Auth:authen authentication script not set for auth realm " .
		   $auth_name, $r->uri);
    return SERVER_ERROR;
  }
  $r->custom_response(AUTH_REQUIRED, $authen_script);
  
  return AUTH_REQUIRED;
}

sub authorize ($$) {
  my ($auth_type, $r) = @_;
  my $debug = $r->dir_config("AuthCookieDebug") || 0;
  
  return OK unless $r->is_initial_req; #only the first internal request
  
  if ($r->auth_type ne $auth_type) {
    $r->log_error($auth_type . "::Auth:authz auth type is " .
		  $r->auth_type) if ($debug >= 3);
    return DECLINED;
  }
  
  my $reqs_arr = $r->requires or return DECLINED;
  
  my $user = $r->connection->user;
  unless ($user) {
    # user is either undef or =0 which means the authentication failed
    $r->log_reason("No user authenticated", $r->uri);
    return FORBIDDEN;
  }
  
  my ($forbidden);
  foreach my $req (@$reqs_arr) {
    my ($requirement, $args) = split /\s+/, $req->{requirement}, 2;
    $args = '' unless defined $args;
    $r->log_error("requirement := $requirement, $args") if $debug >= 2;
    
    next if $requirement eq 'valid-user';
    next if $requirement eq 'user' and $args =~ m/\b$user\b/;

    # Call a custom method
    my $ret_val = $auth_type->$requirement($r, $args);
    $r->log_error("$auth_type->$requirement returned $ret_val") if $debug >= 3;
    next if $ret_val == OK;

    # Nothing succeeded, deny access to this user.
    $forbidden = 1;
    last;
  }

  return $forbidden ? FORBIDDEN : OK;
}


sub authen ($$) {
    my $that = shift;
    my $r = shift;
    my($ses_key_cookie, $cookie_path, $authen_script);
    my($auth_user, $auth_name, $auth_type, $ses_key);

    my $debug = $r->dir_config("AuthCookieDebug") || 0;

    $r->log_error("that " . $that) if ($debug >= 3);
    #only the first internal request
    return OK unless $r->is_initial_req;

    ($auth_type) = ($that =~ /^([^:]+)/);
    $r->log_error("auth_type " . $auth_type) if ($debug >= 2);

    if ($r->auth_type ne $auth_type)
    {
	# This location requires authentication because we are being called,
	# but we don't handle this AuthType.
	$r->log_error($auth_type . "::Auth:authen auth type is " .
	$r->auth_type) if ($debug >= 3);
	return DECLINED;
    }

    # Ok, the AuthType is $auth_type which we handle, what's the authentication
    # realm's name?
    $auth_name = $r->auth_name;
    $r->log_error("auth_name " . $auth_name) if ($debug >= 2);
    if (!($auth_name))
    {
	$r->log_reason($auth_type . "::Auth:authen need AuthName ", $r->uri);
	return SERVER_ERROR;
    }

    # There should also be a PerlSetVar directive that give us the path
    # to set in Set-Cookie header for this realm.
    $cookie_path = $r->dir_config($auth_name . "Path");
    if (!($cookie_path)) {
	$r->log_reason($auth_type . "::Auth:authen path not set for " .
	    "auth realm " .  $auth_name, $r->uri);
	return SERVER_ERROR;
    }


    # Get the Cookie header. If there is a session key for this realm, strip
    # off everything but the value of the cookie.
    ($ses_key_cookie) = ( ($r->header_in("Cookie") || "") =~ 
	/${auth_type}_${auth_name}=([^;]+)/);
    $ses_key_cookie = "" unless defined($ses_key_cookie);
    $ses_key = $ses_key_cookie;

    $r->log_error("ses_key_cookie " . $ses_key_cookie) if ($debug >= 1);
    $r->log_error("cookie_path " . $cookie_path) if ($debug >= 2);
    $r->log_error("uri " . $r->uri) if ($debug >= 2);

    if (! $ses_key_cookie && defined($r->args))
    {
	# No session key set, but the method is post. We should be
	# coming back with the users credentials.

	# If not, we are eating up the posted content so the
	# user will be SOL
	my %args = $r->args;
	if ($args{'AuthName'} ne $auth_name ||
	    $args{'AuthType'} ne $r->auth_type)
	{
	    $r->log_reason($auth_type . "::Auth:authen credentials are " .
		"not for this realm", $r->uri);
	    return SERVER_ERROR;
	}

	# Get the credentials from the data posted by the client
	my @credentials;
	while ($args{"credential_" . ($#credentials + 1)})
	{
	    $r->log_error("credential_" . ($#credentials + 1) . " " .
	    $args{"credential_" . ($#credentials + 1)}) if ($debug >= 2);
	    push(@credentials, $args{"credential_" . ($#credentials + 1)});
	}

	# Exchange the credentials for a session key. If they credentials
	# fail this should return nothing, which will fall trough to call
	# the get credentials script again
	$ses_key = $that->authen_cred($r, @credentials);
	$r->log_error("ses_key " . $ses_key) if ($debug >= 2);
    }
    elsif (! $ses_key_cookie && $r->method_number != M_GET)
    {
	# They aren't authenticated, but they are trying a POST or
	# something, this is not allowed.
	$r->log_reason($auth_type . "::Auth:authen auth header is not set " .
	     "and method is not GET ", $r->uri);
	return SERVER_ERROR;
    }

    if ($ses_key) {
	# We have a session key. So, lets see if it's valid. If it is
	# we return with an OK value. If not then we fall through to
	# call the get credentials script.
	if ($auth_user = $that->authen_ses_key($r, $ses_key)) {
	    if (!($ses_key_cookie)) {
		# They session key is valid, but it's not yet set on
		# the client. So, send the Set-Cookie header.
		$r->err_header_out("Set-Cookie" => $auth_type . "_" .
		    $auth_name .  "=" . $ses_key . "; path=" .  $cookie_path);
		$r->log_error("set_cookie " . $r->err_header_out("Set-Cookie"))
		    if ($debug >= 2);

		# Redirect the client to the same page, but without the
		# query string in the URL. This forces the
		# client to reload the page and keeps it
		# from displaying the credentials in the "Location".
		$r->no_cache(1);
                $r->err_header_out("Pragma", "no-cache");
                $r->header_out("Location" => $r->uri);
                return REDIRECT;
	    }
	    # Tell the rest of Apache what the authentication method and
	    # user is.
	    $r->no_cache(1);
	    $r->err_header_out("Pragma", "no-cache");
	    $r->connection->auth_type($auth_type);
	    $r->connection->user($auth_user);
	    $r->log_error("user authenticated as " . $auth_user)
		if ($debug >= 1);
	    return OK;
	}
    }

    # There was a session key set, but it's invalid for some reason. So,
    # remove it from the client now so when the credential data is posted
    # we act just like it's a new session starting.
    if ($ses_key_cookie) {
	$r->err_header_out("Set-Cookie" => $auth_type . "_" . $auth_name .
	    "=; path=" .  $cookie_path .
	    "; expires=Mon, 21-May-1971 00:00:00 GMT");
	$r->log_error("set_cookie " . $r->err_header_out("Set-Cookie"))
	    if ($debug >= 2);
    }

    # They aren't authenticated, and they tried to get a protected
    # document. Send them the authen form.

    if (defined($r->args)) {
	# Redirect the client to the same page, but without the
	# query string in the URL. This forces the
	# client to reload the page and keeps it
	# from displaying the credentials in the "Location".
	$r->err_header_out("Pragma", "no-cache");
	$r->header_out("Location" => $r->uri);
	return REDIRECT;
    } else {
	# There should also be a PerlSetVar directive that give us the name
	# and location of the script to execute for the authen page.
	$authen_script = $r->dir_config($auth_name . "LoginScript")
	    || "";
	if (!($authen_script)) {
	    $r->log_reason($auth_type . 
		"::Auth:authen authentication script not set for auth realm " .
		$auth_name, $r->uri);
	    return SERVER_ERROR;
	}
	$r->custom_response(AUTH_REQUIRED, $authen_script);

	return AUTH_REQUIRED;
    }
}

sub authz ($$) {
    my $that = shift;
    my $r = shift;
    my($auth_name, $auth_type);

    my $debug = $r->dir_config("AuthCookieDebug") || 0;

    return OK unless $r->is_initial_req; #only the first internal request

    ($auth_type) = ($that =~ /^([^:]+)/);

    if ($r->auth_type ne $auth_type) {
	$r->log_error($auth_type . "::Auth:authz auth type is " .
	    $r->auth_type) if ($debug >= 3);
	return DECLINED;
    }

    my $reqs_arr = ($r->requires || "");
    return OK unless $reqs_arr;

    my $user = $r->connection->user;
    if (!($user)) {
	# user is either undef or =0 which means the authentication failed
	$r->log_reason("No user authenticated", $r->uri);
	return FORBIDDEN;
    }

    my($reqs, $requirement, $args, $restricted);
    foreach $reqs (@$reqs_arr) {
        ($requirement, $args) = split /\s+/, $reqs->{requirement}, 2;
	$args = "" unless defined($args);
	$r->log_error("requirement := $requirement, $args") if ($debug >= 2);

	if ($requirement eq "valid-user") {
	    return OK;
	} elsif ($requirement eq "user") {
	    return OK if ($args =~ m/\b$user\b/);
	} else {
	    my $req_method;
	    if ($req_method = $that->can($requirement)) {
		my $ret_val = &$req_method($that, $r, $args);
		 $r->log_error($that . 
		   " called requirement method " . $requirement . 
		   " which returned " . $ret_val) if ($debug >= 3);
		return OK if ($ret_val == OK);
	    } else {
		$r->log_error($that . 
		    " tried to call undefined requirement method " .
		    $requirement);
	    }
	}
        $restricted++;
    }

    return OK unless $restricted;
    return FORBIDDEN;
}

1;
__END__

=head1 NAME

Apache::AuthCookie - Perl Authentication and Authorization via cookies

=head1 SYNOPSIS

C<use mod_perl qw(1.07 StackedHandlers MethodHandlers Authen Authz);>

=for html
<PRE>
=end html

 # mod_perl startup script

 use Sample::AuthCookieHandler;

 # access.conf or .htaccess

 <Location /unprotected/protected>
    PerlAuthenHandler Sample::AuthCookieHandler->authen
    PerlAuthzHandler Sample::AuthCookieHandler->authz
    AuthType Sample
    AuthName WhatEver
    PerlSetVar WhatEverPath /unprotected
    PerlSetVar WhatEverLoginScript /unprotected/login.pl
    require valid-user
 </Location>

=for html
</PRE>
=end html

=head1 DESCRIPTION

B<Apache::AuthCookie> allows you to intercept a users first
unauthenticated access to a protected document. The user will be
presented with a custom form where they can enter thier authentication
credentials. The credentials are posted to the server where AuthCookie
verifies them and generates a session key.

The session key is returned to the user's browser as a cookie. As a
cookie, the browser will pass the session key on every subsequent
accesses. AuthCookie will verify the session key and re-authenticate
the user.

All you have to do is write a custom package that inheriets from
AuthCookie.  Your package implements two functions:

=over 4

=item C<authen_cred()>

Verify the credentials and return a session key.

=item C<authen_ses_key()>

Verify the session key and return the user ID.

=back

Using AuthCookie versus AuthBasic you get two key benefits.

=over 4

=item 1.

The client doesn't *have* to pass the user credentials on every
subsequent access. You have to do a little more work to get this
feature, by having C<authen_cred()> generate a session key.

=item 2.

When you determine that the client should stop using the
credentials/session key, the server can tell the client to delete the
cookie.

=back

This is the flow of the authentication handler, less the details of the
redirects. Two REDIRECT's are used to keep the client from displaying
the user's credentials in the Location field. They don't really change
AuthCookie's model, but they do add another round-trip request to the
client.

=for html
<PRE>

 (-----------------------)     +---------------------------------+
 ( Request a protected   )     | AuthCookie sets custom error    |
 ( page, but user hasn't )---->| document and returns            |
 ( authenticated (no     )     | AUTH_REQUIRED. Apache abandons  |      
 ( session key cookie)   )     | current request and creates sub |      
 (-----------------------)     | request for the error document. |<-+
                               | Error document is a script that |  |
                               | generates a form where the user |  |
                 return        | enters authentication           |  |
          ^------------------->| credentials (login & password). |  |
         / \      False        +---------------------------------+  |
        /   \                                   |                   |
       /     \                                  |                   |
      /       \                                 V                   |
     /         \               +---------------------------------+  |
    /   Pass    \              | User's client submits this form |  |
   /   user's    \             | to the same URL as the original |  |
   | credentials |<------------| request. AuthCookie sees that   |  |
   \     to      /             | the user isn't authenticated but|  |
    \authen_cred/              | this time there are credentials |  |
     \ function/               | as part of the request.         |  |
      \       /                +---------------------------------+  |
       \     /                                                      |
        \   /            +------------------------------------+     |
         \ /   return    | Authen cred returns an session     |  +--+
          V------------->| key which is opaque to AuthCookie.*|  |
                True     +------------------------------------+  |
                                              |                  |
               +--------------------+         |      +---------------+
               |                    |         |      | If we had a   |
               V                    |         V      | cookie, add   |
  +----------------------------+  r |         ^      | a Set-Cookie  |
  | If we didn't have a session|  e |T       / \     | header to     |
  | key cookie, add a          |  t |r      /   \    | override the  |
  | Set-Cookie header with this|  u |u     /     \   | invalid cookie|
  | session key. Client then   |  r |e    /       \  +---------------+
  | returns session key with   |  n |    /  pass   \               ^    
  | sucsesive requests         |    |   /  session  \              |    
  +----------------------------+    |  /   key to    \    return   |
               |                    +-| authen_ses_key|------------+
               V                       \             /     False
  +-----------------------------------+ \           /
  | Tell Apache to set Expires header |  \         /
  | set no-cache Pragma header, set   |   \       /
  | user to user ID returned by       |    \     /
  | authen_ses_key, set authentication|     \   /
  | to our type (e.g. AuthCookie).    |      \ /
  +-----------------------------------+       V
         (---------------------)              ^
         ( Request a protected )              |
         ( page, user has a    )--------------+
         ( session key cookie  )                    
         (---------------------)


 *  The session key that the client gets can be anything you
    want. For example, encrypted information about the user, a
    hash of the username and password (similar in function to
    Digest authentication), or the user name and password in
    plain text (similar in function to HTTP Basic
    authentication).

    They only catch is that the authen_ses_key function that you
    create must be able to determine if this session_key is valid
    and map it back to the originally authenticated user ID.

=for html
</PRE>

=head1 EXAMPLE

Try the sample in eg/.

=head2 Install the sample

=over 4

=item 1.

Install eg/Sample into the site_perl directory in your perl5 library
directory.

=item 2.

Install eg/unprotected into your Apache document root directory.

=item 3.

Add C<use Sample::AuthCookieHandler;> to your mod_perl startup script
or C<Sample::AuthCookieHandler> to your PerlModule configuration
directive.

=item 4.

Restart Apache so mod_perl picks up C<Sample::AuthCookieHandler>.

=back

=head2 Tryout the sample

=over 4

=item 1.

Try to access /unprotected/protected/get_me.html. You should instead get
a form requesting a login and password. The sample will validate two
users. The first is login => programmer and password => Hero and the
second is login => some-user with no/any password. You might want to
set your browser to show you cookies before accepting them. Then you
can see what AuthCookie is generating.

=item 2.

As distributed, the .htaccess file in F<eg/unprotected/protected> will allow
either of these user to access the document. However if you change the
line C<require valid-user> to C<require dwarf> in .htaccess only the
user "programmer" will have access. Look at the authorization function
C<dwarf()> in F<eg/Sample/AuthCookieHandler.pm> to see how this works.

=head2 Using a Session Key

Unlike the sample AuthCookieHandler, you have you verify the user's
login and password in C<authen_cred()>, then you do something
like:

    my $date = localtime;
    my $ses_key = MD5->hexhash(join(';', $date, $PID, $PAC));

save C<$ses_key> alogin with the user's login, and return C<$ses_key>.

Now C<authen_ses_key()> looks up the C<$ses_key> passed to it and
returns the saved login.  I use Oracle to store the session key and
retrieve it later, see the ToDo section below for some other ideas.

=head1 KNOWN LIMITATIONS

The first unauthenticated request can not be a POST. B<Apache::AuthCookie>
interupts the initial request with the form for the user credentials.

=head2 ToDo

=over 4

=item *

See if there's a way to allow the initial request to be a POST.  I know
B<Apache::AuthCookie> could save the original POST'ed material but I
don't know how to re-insert this content into the request stream after
the user authenticates.  If you knows of a way, please drop me a note.

=item *

Create a session key store that uses shared memory.  If anyone wants to
get together and help with this that would be cool.  Storing and
retrieving them should be easy, but the harder part is cleaning out
"old" keys and dealing with server restarts without losing all the
keys.

=back

=head1 AUTHOR

Eric Bartley, bartley@purdue.edu

=head1 SEE ALSO

L<perl(1)>, L<mod_perl(1)>, L<Apache(1)>.

=cut
