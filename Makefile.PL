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
        'Apache::Test' => 1.22,
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
