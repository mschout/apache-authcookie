use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

print "\nApache::AuthCookie requires that you enabled the following\n";
print "handlers when you compiled mod_perl:\n";
print "\tAuthen Handler\n";
print "\tAuthz Handler\n";
print "\tStacked Handlers\n";
print "\tMethod Handlers\n\n";

WriteMakefile(
    'NAME'	=> 'Apache::AuthCookie',
    'VERSION_FROM' => 'AuthCookie.pm', # finds $VERSION
    dist => {
	 SUFFIX => 'gz',
         COMPRESS => 'gzip -9',
    }
);
