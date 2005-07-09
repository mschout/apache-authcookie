# TODO: handle line-endings better.  Perhaps we should just look for an 
# identifying part of each page rather than trying to do an exact match
# of the entire page.  The problem is on win32, some responses come back with
# dos-style line endings (not all of them though).  Not sure what MacOS does
# and I don't have a Mac to test with.  Currently, we just strip CR's out of
# responses to make the tests pass on Unix and Win32.

use strict;
use warnings FATAL => 'all';
use lib 'lib';

use Apache::Test ':withtestmore';
use Test::More;
use Apache::TestUtil;
use Apache::TestRequest qw(GET POST GET_BODY);

Apache::TestRequest::user_agent( reset => 1, requests_redirectable => 0 );

plan tests => 30, need_lwp;

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
