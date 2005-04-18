
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
    my $data = GET_BODY $url;

    print "# data: $data";
    my $exp = get_expected('3');
    if ($data eq $exp) {
        return 1;
    }
    else { 
        return 0;
    }
}

sub test_4 {
    my $url = '/docs/protected/get_me.html';
    my $r = GET $url;

    print "# CODE: ", $r->code, "\n";
    print "# BODY: ", $r->content;

    my $dat = $r->content;

    my $exp = get_expected('4');
    print "expected: $exp, got: $dat\n";

    return $dat eq $exp;
}

# should succeed with redirect.
sub test_5 {
    my $r = POST('/LOGIN', [
        destination  => '/docs/protected/get_me.html',
        credential_0 => 'programmer',
        credential_1 => 'Hero'
    ]);

    unless ($r->code == 302) {
        printf "# code: %d\n", $r->code;
        return 0;
    }

    return 1;
}

sub test_6 {
    my $uri = '/docs/protected/get_me.html';

    my $r = GET(
        $uri,
        Cookie => 'Sample::AuthCookieHandler_WhatEver=programmer:Hero;'
    );

    my $exp = get_expected('6');

    return $r->content eq $exp;
}

# should fail with no_cookie
sub test_7 {
    my $url = '/docs/protected/get_me.html';

    my $dat = GET_BODY($url);

    my $exp = get_expected('7');

    print "expected: $exp\n";
    print "got: $dat\n";

    return $dat eq $exp;
}

# should have a Set-Cookie header that expired at epoch.
sub test_8 {
    my $url = '/docs/logout.pl';

    my $r = GET($url);

    my $data = $r->header('Set-Cookie');
    my $expected = 'Sample::AuthCookieHandler_WhatEver=; expires=Mon, 21-May-1971 00:00:00 GMT; path=/';

    print "# expected: $data\n";
    print "# got: $data\n";

    return $data eq $expected;
}

sub test_9 {
    my $data = GET_BODY(
        '/docs/echo_cookie.pl',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=programmer:Hero;'
    );

    my $expected = get_expected('9');

    return $data eq $expected;
}

# should fail
sub test_10 {
    my $r = GET(
        '/docs/protected/get_me.html',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=some-user:duck;'
    );

    my $data = $r->code;
    my $expected = '403';

    print "# expected: $expected\n";
    print "# got: $data\n";

    return $data eq $expected;
}

# Should redirect to /docs/protected/get_me.html
sub test_11 {
    my $r = POST('/LOGIN', [
        destination  => '/docs/protected/get_me.html',
        credential_0 => 'programmer',
        credential_1 => 'Heroo'
    ]);

    print "Location: ", $r->header('Location'), "\n",
          "Set-Cookie: ", $r->header('Set-Cookie'), "\n",
          "Code: ", $r->code, "\n";

    return 0 unless
       $r->header('Location') eq '/docs/protected/get_me.html';

    return 0 unless 
        $r->header('Set-Cookie') eq 'Sample::AuthCookieHandler_WhatEver=programmer:Heroo; path=/';

    return 0 unless $r->code == 302;

    return 1;
}

# should get the login form back (bad_cookie).
sub test_12 {
    my $data = GET_BODY(
        '/docs/protected/get_me.html',
        Cookie=>'Sample::AuthCookieHandler_WhatEver=programmer:Heroo'
    );

    my $expected = get_expected('12');

    print "# expected: $expected\n";
    print "# got: $data\n";

    return $data eq $expected;
}

# should get the login form back (bad_credentials)
sub test_13 {
    my $r = POST('/LOGIN', [
        destination  => '/docs/protected/get_me.html',
        credential_0 => 'fail',
        credential_1 => 'Hero'
    ]);

    my $data = $r->content;
    my $expected = get_expected('13');

    print "# expected: $expected\n";
    print "# got: $data\n";

    return $data eq $expected;
}

# check that the destination is right.
sub test_14 {
    my $r = POST('/LOGIN', [
        destination  => '/docs/authany/get_me.html',
        credential_0 => 'some-user',
        credential_1 => 'mypassword'
    ]);

    print "Location: ", $r->header('Location'), "\n",
          "Set-Cookie: ", $r->header('Set-Cookie'), "\n",
          "Code: ", $r->code(), "\n";

    return 0 unless $r->header('Location') eq '/docs/authany/get_me.html';

    return 0 unless 
        $r->header('Set-Cookie') eq 'Sample::AuthCookieHandler_WhatEver=some-user:mypassword; path=/';

    return 0 unless $r->code == 302;

    return 1;
}

# should fail because all requirements are not met
sub test_15 {
    my $r = GET(
        '/docs/authall/get_me.html',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=some-user:mypassword'
    );

    print "code: ", $r->code(), "\n";

    return ($r->code() == 403);
}

sub test_16 {
    my $r = POST('/docs/protected/get_me.html', [
        foo => 'bar'
    ]);

    my $data = $r->content;
    my $expected = get_expected('16');

    print "# expected: $expected\n";
    print "# got: $data\n";

    return $data eq $expected;
}

# same test at #16, but in GET mode. Should succeed
sub test_17 {
    my $data = GET_BODY('/docs/protected/get_me.html?foo=bar');
    my $expected = get_expected('17');

    print "# expected: $expected\n";
    print "# got: $data\n";

    return $data eq $expected;
}

# should succeed (any requirement is met)
sub test_18 {
    my $r = GET(
        '/docs/authany/get_me.html',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=some-user:mypassword'
    );

    my $data = $r->content;
    my $expected = get_expected('18');

    print "# expected: $expected\n";
    print "# got: $data\n";

    return $data eq $expected;
}

# should fail: AuthAny and NONE of the requirements are met.
sub test_19 {
    my $r = GET(
        '/docs/authany/get_me.html',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=nouser:mypassword'
    );

    print "code: ", $r->code(), "\n";

    return ($r->code() == 403);
}

# Should succeed and cookie should have HttpOnly attribute
sub test_20 {
    my $r = POST('/LOGIN-HTTPONLY', [
        destination  => '/docs/protected/get_me.html',
        credential_0 => 'programmer',
        credential_1 => 'Heroo'
    ]);

    print "# Location: ", $r->header('Location'), "\n",
          "# Set-Cookie: ", $r->header('Set-Cookie'), "\n",
          "# Code: ", $r->code, "\n";

    return 0 unless
       $r->header('Location') eq '/docs/protected/get_me.html';

    return 0 unless 
        $r->header('Set-Cookie') eq 'Sample::AuthCookieHandler_WhatEver=programmer:Heroo; path=/; HttpOnly';

    return 0 unless $r->code == 302;

    return 1;
}

# test SessionTimeout
sub test_21 {
    my $r = GET(
        '/docs/stimeout/get_me.html',
        Cookie => 'Sample::AuthCookieHandler_WhatEver=programmer:Hero'
    );

    # print STDERR "# Cookie", $r->header('Set-Cookie');

    return 0 unless
        $r->header('Set-Cookie') =~
            /^Sample::AuthCookieHandler_WhatEver=.*expires=.+/;

    return 1;
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

# vim: ft=perl ts=4 ai et sw=4
