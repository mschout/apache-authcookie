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

my %conf;

do {
  print "\n [$default]: ";
  chomp ($conf{httpd} = <STDIN>);
  $conf{httpd} ||= $default;
} until -e $conf{httpd} || !print("$conf{httpd} not found\n");

$default = getpwuid($<) || "nobody";
print "User to run tests under [$default]: ";
chomp ($conf{user} = <STDIN>);
$conf{user} ||= $default;

$default = getgrgid((getpwnam($conf{user}))[3]) || "nobody";
print "Group to run tests under [$default]: ";
chomp ($conf{group} = <STDIN>);
$conf{group} ||= $default;

$default = 8228;
print "Port to run tests under [$default]: ";
chomp ($conf{port} = <STDIN>);
$conf{port} ||= $default;


open LOC, ">t/httpd.loc" or die "can't write t/httpd.loc: $!";
print LOC map {"$_=$conf{$_}\n"} keys %conf;
close LOC;

my $module = 'Apache::AuthCookie';
my ($name, $dir);
($name = $module) =~ s/.*::(\w+)/$1.pm/;
($dir  = $module) =~ s/::/-/g;

WriteMakefile
  (
   'NAME'       => $module,
   'VERSION_FROM' => $name, # finds $VERSION
   'dist' => { COMPRESS=>"gzip",
               SUFFIX=>"gz",
               PREOP=>('rm -f Changes README; '.
                       "cvs log $name | \$(PERL) -MCVS::Parse -e prettylog > Changes; ".
                       "pod2text -80 < $name > README; ".
                       "cp -f Changes README $dir-\$(VERSION); "
                      ),
             },
   'clean' => {FILES => "t/httpd.loc"},
  );
