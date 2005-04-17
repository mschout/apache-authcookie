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
        'Apache::Test' => 1.09
    },
    'clean'        => {
        FILES => "@CLEAN_FILES"
    }
);

if ($mp_version == 2) {
    # 1.9922 is 2.0.0 RC5. mod_perl package renames happend at this release.
    $makeconf->{PREREQ_PM}{mod_perl} = '1.9922';
}

WriteMakefile(%makeconf);

# inspired by Apache::Peek 1.01
sub test_configure {
    if (eval { require Apache::TestMM }) {
        # enable "make test"
        Apache::TestMM->import(qw(test clean));

        # accept configs from command line.
        Apache::TestMM::filter_args();

        Apache::TestMM::generate_script('t/TEST');

        push @CLEAN_FILES, 't/TEST';
    }
    else {
        # overload test rule with a no-op
        warn "***: You should install Apache::Test to do real testing\n";
        *MY::test = sub {
            return <<'EOF';
test : pure_all
	@echo \*** This test suite requires Apache::Test available from CPAN
EOF
        }
    }
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

    die "mod_perl version $mod_perl::VERSION is not supported\n";
}
