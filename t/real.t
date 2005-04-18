# TODO: handle line-endings better.  Perhaps we should just look for an 
# identifying part of each page rather than trying to do an exact match
# of the entire page.  The problem is on win32, some responses come back with
# dos-style line endings (not all of them though).  Not sure what MacOS does
# and I don't have a Mac to test with.  Currently, we just strip CR's out of
# responses to make the tests pass on Unix and Win32.

use strict;
use warnings FATAL => 'all';
use lib 'lib';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest qw(GET POST GET_BODY);

Apache::TestRequest::user_agent( reset => 1, requests_redirectable => 0 );

plan tests => 21, need_lwp;

ok 1;  # we loaded.

ok 1;  # blank test just to keep check/* numbering matching.

ok test_3();
ok test_4();
ok test_5();
ok test_6();
ok test_7();
ok test_8();
ok test_9();
ok test_10();
ok test_11();
ok test_12();
ok test_13();
ok test_14();
ok test_15();
ok test_16();
ok test_17();
ok test_18();
ok test_19();
ok test_20();
ok test_21();

sub test_3 {
    my $url = '/docs/index.html';
    my $data = strip_cr(GET_BODY $url);

    my $exp = get_expected('3');

    return t_cmp($data, $exp, 'test 3');
}

sub test_4 {
    my $url = '/docs/protected/get_me.html';
    my $r = GET $url;

    my $dat = strip_cr($r->content);

    my $exp = get_expected('4');

    return t_cmp($dat, $exp, 'test 4');
}

# should succeed with redirect.
sub test_5 {
    my $r = POST('/LOGIN', [
        destination  => '/docs/protected/get_me.html',
        credential_0 => 'programmer',
        credential_1 => 'Hero'
    ]);

    return t_cmp($r->code, 302, 'test 5');
}

sub test_6 {
    my $uri = '/docs/protected/get_me.html';

    my $r = GET(
        $uri,
        Cookie => 'Sample::AuthCookieHandler_WhatEver=programmer:Hero;'
    );

    my $exp = get_expected('6');

    return t_cmp(strip_cr($r->content), $exp, 'test 6');
}

# should fail with no_cookie
sub test_7 {
    my $url = '/docs/protected/get_me.html';

    my $dat = strip_cr(GET_BODY($url));

    my $exp = get_expected('7');

    return t_cmp($dat, $exp, 'test 7');
}

# should have a Set-Cookie header that expired at epoch.
sub test_8 {
    my $url = '/docs/logout.pl';

    my $r = GET($url);

    my $data = $r->header('Set-Cookie');
    my $expected = 'Sample::AuthCookieHandler_WhatEver=; expires=Mon, 21-May-1971 00:00:00 GMT; path=/';

    return t_cmp($data, $expected, 'test 8');
}

sub test_9 {
    my $data = GET_BODY(
        '/docs/echo_cookie.pl',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=programmer:Hero;'
    );

    my $expected = get_expected('9');

    return t_cmp(strip_cr($data), $expected, 'test 9');
}

# should fail
sub test_10 {
    my $r = GET(
        '/docs/protected/get_me.html',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=some-user:duck;'
    );

    return t_cmp($r->code, '403', '403 == 403?');
}

# Should redirect to /docs/protected/get_me.html
sub test_11 {
    my $r = POST('/LOGIN', [
        destination  => '/docs/protected/get_me.html',
        credential_0 => 'programmer',
        credential_1 => 'Heroo'
    ]);

    return 0 unless
       $r->header('Location') eq '/docs/protected/get_me.html';

    return 0 unless 
        $r->header('Set-Cookie') eq 'Sample::AuthCookieHandler_WhatEver=programmer:Heroo; path=/';

    return t_cmp($r->code, 302, 'r->code == 302?');
}

# should get the login form back (bad_cookie).
sub test_12 {
    my $data = GET_BODY(
        '/docs/protected/get_me.html',
        Cookie=>'Sample::AuthCookieHandler_WhatEver=programmer:Heroo'
    );

    my $expected = get_expected('12');

    return t_cmp(strip_cr($data), $expected, 'test 12');
}

# should get the login form back (bad_credentials)
sub test_13 {
    my $r = POST('/LOGIN', [
        destination  => '/docs/protected/get_me.html',
        credential_0 => 'fail',
        credential_1 => 'Hero'
    ]);

    my $data = strip_cr($r->content);
    my $expected = get_expected('13');

    return t_cmp($data, $expected, 'test 13');
}

# check that the destination is right.
sub test_14 {
    my $r = POST('/LOGIN', [
        destination  => '/docs/authany/get_me.html',
        credential_0 => 'some-user',
        credential_1 => 'mypassword'
    ]);

    return 0 unless $r->header('Location') eq '/docs/authany/get_me.html';

    return 0 unless 
        $r->header('Set-Cookie') eq 'Sample::AuthCookieHandler_WhatEver=some-user:mypassword; path=/';

    return t_cmp($r->code, 302, 'r->code == 302?');
}

# should fail because all requirements are not met
sub test_15 {
    my $r = GET(
        '/docs/authall/get_me.html',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=some-user:mypassword'
    );

    return t_cmp($r->code(), 403, 'r->code == 403?');
}

sub test_16 {
    my $r = POST('/docs/protected/get_me.html', [
        foo => 'bar'
    ]);

    my $data = strip_cr($r->content);
    my $expected = get_expected('16');

    return t_cmp($data, $expected, 'test 16');
}

# same test at #16, but in GET mode. Should succeed
sub test_17 {
    my $data = GET_BODY('/docs/protected/get_me.html?foo=bar');
    my $expected = get_expected('17');

    return t_cmp(strip_cr($data), $expected, 'test 17');
}

# should succeed (any requirement is met)
sub test_18 {
    my $r = GET(
        '/docs/authany/get_me.html',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=some-user:mypassword'
    );

    my $data = strip_cr($r->content);
    my $expected = get_expected('18');

    return t_cmp($data, $expected, 'test 18');
}

# should fail: AuthAny and NONE of the requirements are met.
sub test_19 {
    my $r = GET(
        '/docs/authany/get_me.html',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=nouser:mypassword'
    );

    return t_cmp($r->code, 403, 'r->code == 403?');
}

# Should succeed and cookie should have HttpOnly attribute
sub test_20 {
    my $r = POST('/LOGIN-HTTPONLY', [
        destination  => '/docs/protected/get_me.html',
        credential_0 => 'programmer',
        credential_1 => 'Heroo'
    ]);

    return 0 unless
       $r->header('Location') eq '/docs/protected/get_me.html';

    return 0 unless 
        $r->header('Set-Cookie') eq 'Sample::AuthCookieHandler_WhatEver=programmer:Heroo; path=/; HttpOnly';

    return t_cmp($r->code, 302, 'r->code == 302');
}

# test SessionTimeout
sub test_21 {
    my $r = GET(
        '/docs/stimeout/get_me.html',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=programmer:Hero'
    );

    return t_cmp($r->header('Set-Cookie'),
                 qr/^Sample::AuthCookieHandler_WhatEver=.*expires=.+/,
                 'Set-Cookie contains expires property?');
}

# get the "expected output" file for a given test and return its contents.
sub get_expected {
    my ($fname) = @_;

    local $/ = undef;
    open EXPFH, "< t/check/$fname" or die "cant open check/$fname: $!";
    my $data = <EXPFH>;
    close EXPFH;

    return $data;
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
