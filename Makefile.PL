use ExtUtils::MakeMaker;
use lib 't/lib';
use Apache::test;

my %params = Apache::test->get_test_params();
Apache::test->write_httpd_conf( %params, include => join('', <DATA>) );
*MY::test = sub { Apache::test->MM_test(%params) };

WriteMakefile(
    'NAME'         => 'Apache::AuthCookie',
    'VERSION_FROM' => 'AuthCookie.pm',
    'PREREQ_PM'    => { 'CGI::Util' => 0 },
    'clean'        => {FILES => 't/httpd.conf t/httpd.loc t/error_log t/httpd'},
    'dist'         => {PREOP=>('rm -f README; '.
                              'pod2text -80 < AuthCookie.pm > README; '.
                              'cp -f README $(DISTNAME)-$(VERSION);')}
);

__DATA__
PerlModule Apache::AuthCookie
PerlModule Sample::AuthCookieHandler

PerlSetVar WhatEverPath /
PerlSetVar WhatEverLoginScript /docs/login.pl
PerlSetVar AuthCookieDebug 3

# These documents require user to be logged in.
<Location /docs/protected>
 AuthType Sample::AuthCookieHandler
 AuthName WhatEver
 PerlAuthenHandler Sample::AuthCookieHandler->authenticate
 PerlAuthzHandler Sample::AuthCookieHandler->authorize
 Require user programmer
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
