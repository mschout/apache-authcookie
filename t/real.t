#!/usr/bin/perl

use strict;
use lib qw(lib t/lib);

use Apache::test qw(skip_test have_httpd test);
skip_test unless have_httpd;

use vars qw($TEST_NUM);

my %requests = (
   3  => '/docs/index.html',

   # Should fail with 'no_cookie'
   4  => '/docs/protected/get_me.html',

   # Should succeed (redirect)
   5  => {uri=>'/LOGIN',
	  method=>'POST',
	  content=>'destination=/docs/protected/get_me.html&credential_0=programmer&credential_1=Hero',
	 },

   # Should succeed
   6  => {uri=>'/docs/protected/get_me.html',
	  method=>'GET',
	  headers=>{Cookie=>'Sample::AuthCookieHandler_WhatEver=programmer:Hero;'},
	 },

   # Should fail with 'no_cookie'
   7  => {uri=>'/docs/protected/get_me.html',
	  method=>'GET',
	  content=>'destination=/docs/protected/get_me.html&credential_0=programmer&credential_1=Heroo',
	 },

   8  => '/docs/logout.pl',

   9  => {uri=>'/docs/echo_cookie.pl',
	  method=>'GET',
	  headers=>{Cookie=>'Sample::AuthCookieHandler_WhatEver=programmer:Hero;'},
	 },

   # Should fail
   10 => {uri=>'/docs/protected/get_me.html',
	  method=>'GET',
	  headers=>{Cookie=>'Sample::AuthCookieHandler_WhatEver=some-user:duck;'},
	 },

   # Should redirect to /docs/protected/get_me.html
   11 => {uri=>'/LOGIN',
	  method=>'POST',
	  content=>'destination=/docs/protected/get_me.html&credential_0=programmer&credential_1=Heroo',
	 },

   # Should fail with 'bad_cookie'
   12 => {uri=>'/docs/protected/get_me.html',
	  method=>'GET',
	  headers=>{Cookie=>'Sample::AuthCookieHandler_WhatEver=programmer:Heroo'},
	 },

   # should get the login form back (bad_credentials).
   # Check that destination is right.
   13  => {uri=>'/LOGIN',
	   method=>'POST',
	   content=>'destination=/docs/protected/get_me.html&credential_0=fail&credential_1=Hero',
	 },

    # auth any should get the page
    14 => {uri => '/LOGIN',
           method => 'POST',
           content => join('&', 'destination=/docs/authany/get_me.html',
                                'credential_0=some-user',
                                'credential_1=mypassword')
          },                       

    # auth all should fail because we have 2 user requirements
    # so we should get FORBIDDEN
    15 => {uri     => '/docs/authall/get_me.html',
           method  => 'GET',
           headers => {Cookie => 'Sample::AuthCookieHandler_WhatEver=some-user:mypassword'}
          },
);

my %special_tests = (
   5  => sub {print "code: ", $_[0]->code(), "\n"; $_[0]->code() == 302},
   8  => sub {$_[0]->header('Set-Cookie') 
		eq 'Sample::AuthCookieHandler_WhatEver=; expires=Mon, 21-May-1971 00:00:00 GMT; path=/'},
   10 => sub {print "code: ", $_[0]->code(), "\n"; $_[0]->code() == 403},
   11 => sub {
       my $r = shift;
       print("Location: ", $r->header('Location'), "\n",
	     "Set-Cookie: ", $r->header('Set-Cookie'), "\n", 
	     "Code: ", $r->code(), "\n");

       my $ok = 1;
       $ok = 0 unless $r->header('Location')   eq '/docs/protected/get_me.html';
       $ok = 0 unless $r->header('Set-Cookie') eq 'Sample::AuthCookieHandler_WhatEver=programmer:Heroo; path=/';
       $ok = 0 unless $r->code() == 302;
       return $ok;
   },
   14 => sub {
        my $r = shift;
        print("Location: ", $r->header('Location'), "\n",
              "Set-Cookie: ", $r->header('Set-Cookie'), "\n",
              "Code: ", $r->code(), "\n");
        
        my $ok = 1;

        $ok = 0 unless $r->header('Location') eq '/docs/authany/get_me.html';
        $ok = 0 unless $r->header('Set-Cookie') eq 
                'Sample::AuthCookieHandler_WhatEver=some-user:mypassword; path=/';
        $ok = 0 unless $r->code() == 302;

        return $ok;
   },
   15 => sub {
        my $r = shift;
        print "code: ", $r->code(), "\n";
        return ($r->code() == 403);
   },
);

print "1.." . (2 + keys %requests) . "\n";

test ++$TEST_NUM, 1;
test ++$TEST_NUM, 1;

foreach my $testnum (sort {$a <=> $b} keys %requests) {
	test_outcome(Apache::test->fetch($requests{$testnum}), $testnum);
}

sub test_outcome {
	my ($response, $i) = @_;
	my $content = $response->content;
	#warn "($content, $response, $i)\n";
  
  my ($text, $expected);
  my $ok = ($special_tests{$i} ?
	    $special_tests{$i}->($response) :
	    ($content eq ($expected = `cat t/check/$i`)) );
	Apache::test->test(++$TEST_NUM, $ok);
  my $headers = $response->headers_as_string();
  print "Result: $headers\n$text\nExpected: $expected\n" if ($ENV{TEST_VERBOSE} and not $ok);
}
