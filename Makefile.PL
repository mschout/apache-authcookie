use ExtUtils::MakeMaker;
use File::Spec;
use File::Copy;

my @CLEAN_FILES = ();
my $mp_version = mod_perl_version();
test_prepare($mp_version);

test_configure();

my %makeconf = (
    'NAME'         => 'Apache::AuthCookie',
    'VERSION_FROM' => 'lib/Apache/AuthCookie.pm',
    'PREREQ_PM'    => {
        'Apache::Test' => 1.32,
        'Test::More'   => 0,
        'CGI'          => 0
    },
    'clean'        => {
        FILES => "@CLEAN_FILES"
    }
);

if (MM->can('signature_target')) {
    $makeconf{SIGN} = 1;
}

if ($mp_version == 2) {
    # 1.999022 == 2.0.0 RC5. mod_perl -> mod_perl2 renamed here.
    $makeconf{PREREQ_PM}{mod_perl2} = '1.999022';
    # CGI.pm 3.12 is required to work with mod_perl2
    $makeconf{PREREQ_PM}{CGI} = '3.12';
}
elsif ($mp_version == 1) {
    $makeconf{PREREQ_PM}{mod_perl} = '1.27';
}

WriteMakefile(%makeconf);

# inspired by Apache::Peek 1.01
sub test_configure {
    if (eval { require Apache::TestMM }) {
        if (running_as_root()) {
            warn "***: you cannot run the test suite as root. Tests will be skipped\n";
            *MY::test = \&skip_root_tests;
        }
        else {
            enable_apache_test();
        }
    }
    else {
        # overload test rule with a no-op
        warn "***: You should install Apache::Test to do real testing\n";
        *MY::test = \&skip_no_apache_test;
    }
}

sub enable_apache_test {
    # enable "make test"
    Apache::TestMM->import(qw(test clean));

    # accept configs from command line.
    Apache::TestMM::filter_args();

    Apache::TestMM::generate_script('t/TEST');

    push @CLEAN_FILES, 't/TEST';
}

# Apache::Test just *FAILS* the whole suite if you are running as root.  You
# cannot run the test suite as root because apache wont spawn root children.
# So instead, we just skip the whole test suite with a message if it is
# attempted to run it as root.
# see: http://www.mail-archive.com/dev@perl.apache.org/msg12535.html
sub skip_root_tests {
    return <<'EOF';
test::
	@echo
	@echo Apache::Test tests must be run as a non-privileged user on *nix
	@echo based filesystems.  There are several reasons, but stemming from
	@echo the fact that the httpd process is owned by a non privileged user
	@echo and thus cannot access the test files if they are owned by root.
	@echo
	@echo Please rebuild Apache::Test as a non-privileged user and run the
	@echo tests as that user, then use sudo to install the module.  Or build
	@echo against your own locally installed version of Perl.
	@echo
EOF
}

sub skip_no_apache_test {
    return <<'EOF';
test::
	@echo \*** This test suite requires Apache::Test available from CPAN
EOF
}

sub running_as_root {
    my $user = eval { scalar getpwuid($>) || '' };

    return $user eq 'root' ? 1 : 0;
}

# select the appropriate test files (MP1 vs MP2) and copy them to the correct
# location.
sub test_prepare {
    my $mp_version = shift;

    my $file = File::Spec->catfile(qw(t lib Sample),
                                   "AuthCookieHandler.pm.mp${mp_version}");
    my $outfile = File::Spec->catfile(qw(t lib Sample),
                                      "AuthCookieHandler.pm");
    unless (-f $file) {
        die "whoops.  I cant find $file\n";
    }

    if (-f $outfile) {
        unlink $outfile or die "unlink($outfile): $!";
    }

    warn "selected $file\n";
    File::Copy::copy($file, $outfile);

    push @CLEAN_FILES, $outfile;
}

sub mod_perl_version {
    # try to figure out what version of mod_perl is installed.
    eval {
        require mod_perl
    };
    unless ($@) {
        if ($mod_perl::VERSION >= 1.99) {
            # mod_perl 2 prior to RC5 (1.99_21 or earlier)
            die "mod_perl 2.0.0 RC5 or later is required for this module";
        }

        return 1;
    }

    eval {
        require mod_perl2;
    };
    unless ($@) {
        return 2;
    }

    # we didn't fine a supported version issue a warning, and assume version 2.
    warn "no supported mod_perl version was found\n";

    return 2;
}
