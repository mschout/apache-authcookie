use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $default = $ENV{'APACHE'} || '/usr/lib/httpd/httpd';
$|=1;
print("\nFor testing purposes, please give the full path to an httpd\n",
      "with mod_perl and at least the following hooks enabled: PERL_AUTHEN,\n",
      "PERL_AUTHZ, PERL_STACKED_HANDLERS, PERL_METHOD_HANDLERS.\n",
      "The path defaults to \$ENV{APACHE}, if present.\n",
     );

my $httpd = '';
do {
  print "\n [$default]: ";
  chomp ($httpd = <STDIN>);
  $httpd ||= $default;
} until -e $httpd || !print("$httpd not found\n");

open LOC, ">t/httpd.loc" or die "can't write t/httpd.loc: $!";
print LOC $httpd;
close LOC;

WriteMakefile
  (
   'NAME' => 'Apache::AuthCookie',
   'VERSION_FROM' => 'AuthCookie.pm', # finds $VERSION
   'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
   'clean' => {FILES => "t/httpd.loc"},
  );
