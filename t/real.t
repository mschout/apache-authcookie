#!/usr/bin/perl

# This test will start up a real httpd server with mod_perl loaded in
# it, and make several requests on that server.

# You shouldn't have to change any of these, but you can if you want:
$ACONF = "/dev/null";
$CONF  = "t/httpd.conf";
$SRM   = "/dev/null";
$LOCK  = "t/httpd.lock";
$PID   = "t/httpd.pid";
$ELOG  = "t/error_log";

######################################################################
################ Don't change anything below here ####################
######################################################################

#line 25 real.t

use vars qw(
     $ACONF   $CONF   $SRM   $LOCK   $PID   $ELOG
   $D_ACONF $D_CONF $D_SRM $D_LOCK $D_PID $D_ELOG
);
my $DIR = `pwd`;
chomp $DIR;
&dirify(qw(ACONF CONF SRM LOCK PID ELOG));
&read_httpd_loc();

use strict;
use vars qw($TEST_NUM $BAD %CONF);
use LWP::UserAgent;
use Carp;

my %requests = 
  (
   3  => 'index.html',

   # Should fail with 'no_cookie'
   4  => 'protected/get_me.html',

   # Should succeed (redirect)
   5  => {uri=>'LOGIN',
	  method=>'POST',
	  content=>'destination=/protected/get_me.html&credential_0=programmer&credential_1=Hero',
	 },

   # Should succeed
   6  => {uri=>'protected/get_me.html',
	  method=>'GET',
	  headers=>{Cookie=>'Sample::AuthCookieHandler_WhatEver=programmer:Hero;'},
	 },

   # Should fail with 'no_cookie'
   7  => {uri=>'protected/get_me.html',
	  method=>'GET',
	  content=>'destination=/protected/get_me.html&credential_0=programmer&credential_1=Heroo',
	 },

   8  => 'logout.pl',

   9  => {uri=>'echo_cookie.pl',
	  method=>'GET',
	  headers=>{Cookie=>'Sample::AuthCookieHandler_WhatEver=programmer:Hero;'},
	 },

   # Should fail
   10 => {uri=>'protected/get_me.html',
	  method=>'GET',
	  headers=>{Cookie=>'Sample::AuthCookieHandler_WhatEver=some-user:duck;'},
	 },

   # Should redirect to /protected/get_me.html
   11 => {uri=>'LOGIN',
	  method=>'POST',
	  content=>'destination=/protected/get_me.html&credential_0=programmer&credential_1=Heroo',
	 },

   # Should fail with 'bad_cookie'
   12 => {uri=>'protected/get_me.html',
	  method=>'GET',
	  headers=>{Cookie=>'Sample::AuthCookieHandler_WhatEver=programmer:Heroo'},
	 },

  );

my %special_tests = 
  (
   5  => sub {print "code: ", $_[0]->code(), "\n"; $_[0]->code() == 302},
   8  => sub {$_[0]->header('Set-Cookie') 
		eq 'Sample::AuthCookieHandler_WhatEver=; path=/; expires=Mon, 21-May-1971 00:00:00 GMT'},
   10 => sub {print "code: ", $_[0]->code(), "\n"; $_[0]->code() == 403},
   11 => sub 
     {
       my $r = shift;
       print("Location: ", $r->header('Location'), "\n",
	     "Set-Cookie: ", $r->header('Set-Cookie'), "\n", 
	     "Code: ", $r->code(), "\n");

       my $ok = 1;
       $ok = 0 unless $r->header('Location')   eq '/protected/get_me.html';
       $ok = 0 unless $r->header('Set-Cookie') eq 'Sample::AuthCookieHandler_WhatEver=programmer:Heroo; path=/';
       $ok = 0 unless $r->code() == 302;
       return $ok;
     }
   

  );

print "1.." . (2 + keys %requests) . "\n";

&report( &create_conf() );
my $result = &start_httpd;
&report( $result );

if ($result) {
  local $SIG{'__DIE__'} = \&kill_httpd;
  
  foreach my $testnum (sort {$a<=>$b} keys %requests) {
    my $ua = new LWP::UserAgent;
    my ($meth, $uri, $content, $headers);

    if (ref $requests{$testnum}) {
      # Allow customization of request
      ($meth, $uri, $content) = @{$requests{$testnum}}{'method','uri','content'};
      $headers = $requests{$testnum}{headers};
      $headers->{Content_Type} = 'application/x-www-form-urlencoded'
	if (!$headers and $requests{$testnum}{method} eq 'POST');
      $headers = new HTTP::Headers(%$headers);
    } else {
      ($meth, $uri, $content, $headers) = ('GET', $requests{$testnum}, '', undef);
    }

    my $req = new HTTP::Request($meth, "http://localhost:$CONF{port}/$uri", $headers, $content);
    my $response = $ua->request($req);
    
    &test_outcome($response, $testnum);
  }
  
  &kill_httpd();
  warn "\nSee $ELOG for failure details\n" if $BAD;
} else {
  warn "Aborting real.t";
}

&cleanup();

sub index_ok { $_[0] =~ /index of/i };

#############################

sub read_httpd_loc {
  open LOC, "t/httpd.loc" or die "t/httpd.loc: $!";
  while (<LOC>) {
    $CONF{$1} = $2 if /^(\w+)=(.*)/;
  }
}

sub start_httpd {
  print STDERR "Starting http server... ";
  unless (-x $CONF{httpd}) {
    warn("$CONF{httpd} doesn't exist or isn't executable.\n");
    return;
  }
  &do_system("cp /dev/null $ELOG");
  &do_system("$CONF{httpd} -f $D_CONF") == 0
    or die "Can't start httpd: $!";
  print STDERR "ready. ";
  return 1;
}

sub kill_httpd {
  &do_system("kill -TERM `cat $PID`");
  &do_eval("unlink '$ELOG'") unless $BAD;
  return 1;
}

sub cleanup {
  &do_eval("unlink '$CONF'");
  return 1;
}

sub test_outcome {
  my $response = shift;
  my $i = shift;
  
  my ($text, $expected);
  my $ok = ($special_tests{$i} ?
	    $special_tests{$i}->($response) :
	    (($text = $response->content) eq ($expected = `cat t/check/$i`)) );
  &report($ok);
  my $headers = $response->headers_as_string();
  print "Result: $headers\n$text\nExpected: $expected\n" if ($ENV{TEST_VERBOSE} and not $ok);
}

sub report {
  my $ok = shift;
  $TEST_NUM++;
  print "not "x(!$ok), "ok $TEST_NUM\n";
  $BAD++ unless $ok;
}

sub do_system {
  my $cmd = shift;
  print "$cmd\n";
  return system $cmd;
}

sub do_eval {
  my $code = shift;
  print "$code\n";
  my $result = eval $code;
  if ($@ or !$result) { carp "WARNING: $@" }
  return $result;
}

sub dirify {
  no strict('refs');
  foreach (@_) {
    # Turn $VAR into $D_VAR, which has an absolute path
    ${"D_$_"} = (${$_} =~ m,^/, ? ${$_} : "$DIR/${$_}");
  }
}

sub create_conf {
  my $file = $CONF;
  open (CONF, ">$file") or die "Can't create $file: $!" && return;
  print CONF <<EOF;

#This file is created by the $0 script.

Port $CONF{port}
User $CONF{user}
Group $CONF{group}
ServerName localhost
DocumentRoot $DIR/t/eg

ErrorLog $D_ELOG
PidFile $D_PID
AccessConfig $D_ACONF
ResourceConfig $D_SRM
LockFile $D_LOCK
TypesConfig /dev/null
TransferLog /dev/null
ScoreBoardFile /dev/null

AddType text/html .html

# Look in ./blib/lib
PerlModule ExtUtils::testlib
PerlRequire $DIR/t/Sample/AuthCookieHandler.pm

PerlSetVar WhatEverPath /
PerlSetVar WhatEverLoginScript /login.pl
PerlSetVar AuthCookieDebug 3

# These documents require user to be logged in.
<Location /protected>
 AuthType Sample::AuthCookieHandler
 AuthName WhatEver
 PerlAuthenHandler Sample::AuthCookieHandler->authenticate
 PerlAuthzHandler Sample::AuthCookieHandler->authorize
 require user programmer
</Location>

# These documents don't require logging in, but allow it.
<FilesMatch "\.cgi$">
 AuthType Sample::AuthCookieHandler
 AuthName WhatEver
 PerlFixupHandler Sample::AuthCookieHandler->recognize_user
</FilesMatch>

<FilesMatch "\.pl">
 AuthType Sample::AuthCookieHandler
 AuthName WhatEver
 SetHandler perl-script
 PerlHandler Apache::Registry
 Options +ExecCGI
</FilesMatch>

# This is the action of the login.pl script above.
<Files LOGIN>
 AuthType Sample::AuthCookieHandler
 AuthName WhatEver
 SetHandler perl-script
 PerlHandler Sample::AuthCookieHandler->login
</Files>

<Location /perl-status>
 SetHandler perl-script
 PerlHandler Apache::Status
</Location>

EOF
	
  close CONF;
  
  chmod 0644, $file or warn "Couldn't 'chmod 0644 $file': $!";
  return 1;
}
