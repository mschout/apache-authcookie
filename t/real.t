# TODO: handle line-endings better.  Perhaps we should just look for an 
# identifying part of each page rather than trying to do an exact match
# of the entire page.  The problem is on win32, some responses come back with
# dos-style line endings (not all of them though).  Not sure what MacOS does
# and I don't have a Mac to test with.  Currently, we just strip CR's out of
# responses to make the tests pass on Unix and Win32.  
use strict;
use warnings FATAL => 'all';
use lib 'lib';

use Apache::Test '-withtestmore';
use Apache::TestUtil;
use Apache::TestRequest qw(GET POST GET_BODY);

Apache::TestRequest::user_agent( reset => 1, requests_redirectable => 0 );

plan tests => 46, need_lwp;

ok 1;  # we loaded.

# TODO: the test descriptions should be things other than 'test #' here.

# check that /docs/index.html works.  If this fails, the test environment did
# not configure properly.
{
    my $url = '/docs/index.html';
    my $data = strip_cr(GET_BODY $url);

    like($data, qr/Get the protected document/s,
         '/docs/index.html seems to work');
}

# test no_cookie failure
{
    my $url = '/docs/protected/get_me.html';
    my $r = GET $url;

    like($r->content, qr/Failure reason: 'no_cookie'/s,
         'no_cookie works');
}

# should succeed with redirect.
{
    my $r = POST('/LOGIN', [
        destination  => '/docs/protected/get_me.html',
        credential_0 => 'programmer',
        credential_1 => 'Hero'
    ]);

    is($r->code, 302, 'login produces redirect');
    is($r->header('Location'), '/docs/protected/get_me.html',
       'redirect header exists, and contains expected url');
}

# get protected document with valid cookie.  Should succeed.
{
    my $uri = '/docs/protected/get_me.html';

    my $r = GET(
        $uri,
        Cookie => 'Sample::AuthCookieHandler_WhatEver=programmer:Hero;'
    );

    is($r->code, '200', 'get protected document');
    like($r->content, qr/Congratulations, you got past AuthCookie/s,
         'check protected document content');
}

# should fail with no_cookie
{
    my $url = '/docs/protected/get_me.html';

    my $dat = strip_cr(GET_BODY($url));

    like($dat, qr/Failure reason: 'no_cookie'/s,
         'test failure reason: no_cookie');
}

# should have a Set-Cookie header that expired at epoch.
{
    my $url = '/docs/logout.pl';

    my $r = GET($url);

    my $data = $r->header('Set-Cookie');
    my $expected = 'Sample::AuthCookieHandler_WhatEver=; expires=Mon, 21-May-1971 00:00:00 GMT; path=/';

    is($data, $expected, 'logout tries to delete the cookie');
}

# check the session key
{
    my $data = GET_BODY(
        '/docs/echo_cookie.pl',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=programmer:Hero;'
    );

    is(strip_cr($data), 'programmer:Hero', 'session key contains expected data');
}

# should fail because of 'require user programmer'
{
    my $r = GET(
        '/docs/protected/get_me.html',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=some-user:duck;'
    );

    is($r->code, '403', 'user "some-user" is not authorized');
}

# Should redirect to /docs/protected/get_me.html
{
    my $r = POST('/LOGIN', [
        destination  => '/docs/protected/get_me.html',
        credential_0 => 'programmer',
        credential_1 => 'Heroo'
    ]);

    is($r->code, 302, 'programmer:Heroo login replies with redirect');

    is($r->header('Location'), '/docs/protected/get_me.html',
       'programmer:Heroo location header contains expected URL');

    is($r->header('Set-Cookie'),
       'Sample::AuthCookieHandler_WhatEver=programmer:Heroo; path=/',
       'programmer:Heroo cookie header contains expected data');
}

# should get the login form back (bad_cookie).
{
    my $data = GET_BODY(
        '/docs/protected/get_me.html',
        Cookie=>'Sample::AuthCookieHandler_WhatEver=programmer:Heroo'
    );

    like($data, qr/Failure reason: 'bad_cookie'/, 'invalid cookie');
}

# should get the login form back (bad_credentials)
{
    my $r = POST('/LOGIN', [
        destination  => '/docs/protected/get_me.html',
        credential_0 => 'fail',
        credential_1 => 'Hero'
    ]);

    like($r->content, qr/Failure reason: 'bad_credentials'/,
         'invalid credentials');
}

# check that the destination is right.
{
    my $r = POST('/LOGIN', [
        destination  => '/docs/authany/get_me.html',
        credential_0 => 'some-user',
        credential_1 => 'mypassword'
    ]);

    is($r->header('Location'), '/docs/authany/get_me.html',
       'Location header is correct');

    is($r->header('Set-Cookie'), 
       'Sample::AuthCookieHandler_WhatEver=some-user:mypassword; path=/',
       'Set-Cookie header is correct');

    is($r->code, 302, 'redirect code is correct');
}

# should fail because all requirements are not met
{
    my $r = GET(
        '/docs/authall/get_me.html',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=some-user:mypassword'
    );

    is($r->code(), 403, 'unauthorized if requirements are not met');
}

# test POST to GET conversion
{
    my $r = POST('/docs/protected/get_me.html', [
        foo => 'bar'
    ]);

    like($r->content, qr#"/docs/protected/get_me\.html\?foo=bar"#,
         'POST -> GET conversion works');
}

# same test at #16, but in GET mode. Should succeed
{
    my $data = GET_BODY('/docs/protected/get_me.html?foo=bar');

    like($data, qr#"/docs/protected/get_me\.html\?foo=bar"#,
         'input query string exists in desintation');
}

# should succeed (any requirement is met)
{
    my $r = GET(
        '/docs/authany/get_me.html',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=some-user:mypassword'
    );

    like($r->content, qr/Congratulations, you got past AuthCookie/,
         'AuthAny access allowed');
}

# any requirement, username=0 works.
{
    my $r = GET(
        '/docs/authany/get_me.html',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=0:mypassword'
    );

    like($r->content, qr/Congratulations, you got past AuthCookie/,
         'username=0 access allowed');
}

# login with username=0 works
{
    my $r = POST('/LOGIN', [
        destination  => '/docs/authany/get_me.html',
        credential_0 => '0',
        credential_1 => 'mypassword'
    ]);

    is($r->code, 302, 'username=0 login produces redirect');
    is($r->header('Location'), '/docs/authany/get_me.html',
       'redirect header exists, and contains expected url');
}

# should fail: AuthAny and NONE of the requirements are met.
{
    my $r = GET(
        '/docs/authany/get_me.html',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=nouser:mypassword'
    );

    is($r->code, 403, 'AuthAny forbidden');
}

# Should succeed and cookie should have HttpOnly attribute
{
    my $r = POST('/LOGIN-HTTPONLY', [
        destination  => '/docs/protected/get_me.html',
        credential_0 => 'programmer',
        credential_1 => 'Heroo'
    ]);

    is($r->header('Location'), '/docs/protected/get_me.html',
       'HttpOnly location header');

    is($r->header('Set-Cookie'),
       'Sample::AuthCookieHandler_WhatEver=programmer:Heroo; path=/; HttpOnly',
       'cookie contains HttpOnly attribute');

    is($r->code, 302, 'check redirect response code');
}

# test SessionTimeout
{
    my $r = GET(
        '/docs/stimeout/get_me.html',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=programmer:Hero'
    );

    like($r->header('Set-Cookie'),
         qr/^Sample::AuthCookieHandler_WhatEver=.*expires=.+/,
         'Set-Cookie contains expires property');
}

# should return bad credentials page, and credentials should be in a comment.
# We are checking here that $r->prev->pnotes('WhatEverCreds') works.
{
    my $r = POST('/LOGIN', [
        destination  => '/docs/protected/get_me.html',
        credential_0 => 'fail',
        credential_1 => 'Hero'
    ]);

    like($r->content, qr/creds: fail Hero/s, 'WhatEverCreds pnotes works');
}

# regression - Apache2::URI::unescape_url() does not handle '+' to ' '
# conversion.
{
    my $r = POST('/LOGIN', [
        destination  => '/docs/protected/get_me.html',
        credential_0 => 'fail',
        credential_1 => 'one two'
    ]);

    like($r->content, qr/creds: fail one two/,
         'read form data handles "+" conversion');
}

# variation of '+' to ' ' regression.  Make sure we do not remove encoded
# '+'
{
    my $r = POST('/LOGIN', [
        destination  => '/docs/protected/get_me.html',
        credential_0 => 'fail',
        credential_1 => 'one+two'
    ]);

    like($r->content, qr/creds: fail one\+two/,
         'read form data handles "+" conversion with encoded +');
}

# XSS attack prevention.  make sure embedded \r, \n, \t is escaped in the destination.
{
    my $r = POST('/LOGIN', [
        destination  => "/docs/protected/get_me.html\r\nX-Test-Bar: True\r\nX-Test-Foo: True\r\n",
        credential_0 => 'programmer',
        credential_1 => 'Hero'
    ]);

    ok(!defined $r->header('X-Test-Foo'), 'anti XSS injection');
    ok(!defined $r->header('X-Test-Bar'), 'anti XSS injection');

    # try with escaped CRLF also.
    $r = POST('/LOGIN', [
        destination  => "/docs/protected/get_me.html%0d%0aX-Test-Foo: True%0d%0aX-Test-Bar: True\r\n",
        credential_0 => 'programmer',
        credential_1 => 'Hero'
    ]);

    ok(!defined $r->header('X-Test-Foo'), 'anti XSS injection with escaped CRLF');
    ok(!defined $r->header('X-Test-Bar'), 'anti XSS injection with escaped CRLF');
}

# make sure '/' in password is preserved.
{
    my $r = POST('/LOGIN', [
        destination  => '/docs/protected/get_me.html',
        credential_0 => 'fail',
        credential_1 => 'one/two'
    ]);

    like($r->content, qr/creds: fail one\/two/,
         'read form data handles "/" conversion with encoded +');
}

# make sure multi-valued form data is preserved.
{
    my $r = POST('/docs/protected/xyz', [
        one => 'abc',
        one => 'def'
    ]);

    # check and make sure we are at the login form now.
    like($r->content, qr/Failure reason: 'no_cookie'/,
         'login form was returned');

    # check for multi-valued form data.
    like($r->content, qr/one=abc&one=def/,
         'post conversion perserves multi-valued fields');
}

# make sure $ENV{REMOTE_USER} gets set up
{
    my $r = GET('/docs/protected/echo_user.pl',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=programmer:Hero'
    );

    like($r->content, qr/User: programmer/);
}

# test login form response status=OK with SymbianOS
{
    my $orig_agent = Apache::TestRequest::user_agent()->agent;

    # should get a 403 response by default
    my $r = GET('/docs/protected/get_me.html');
    is $r->code, 403;
    like $r->content, qr/\bcredential_0\b/, 'got login form';

    Apache::TestRequest::user_agent()
        ->agent('Mozilla/5.0 (SymbianOS/9.1; U; [en]; Series60/3.0 NokiaE60/4.06.0) AppleWebKit/413 (KHTML, like Gecko) Safari/413');

    # should get a 200 response for SymbianOS
    $r = GET('/docs/protected/get_me.html');
    is $r->code, 200;
    like $r->content, qr/\bcredential_0\b/, 'got login form';

    Apache::TestRequest::user_agent()->agent($orig_agent);
}

# remove CR's from a string.  Win32 apache apparently does line ending
# conversion, and that can cause test cases to fail because output does not
# match expected because expected has UNIX line endings, and OUTPUT has dos
# style line endings.
sub strip_cr {
    my $data = shift;
    $data =~ s/\r//gs;
    return $data;
}

# vim: ft=perl ts=4 ai et sw=4
