use ExtUtils::MakeMaker;

my @CLEAN_FILES = ();
my $mp_version = mod_perl_version();
build_prepare($mp_version);

test_configure();

WriteMakefile(
    'NAME'         => 'Apache::AuthCookie',
    'VERSION_FROM' => 'AuthCookie.pm',
    'PREREQ_PM'    => {
        'Apache::Test' => 1.01
    },
    'clean'        => {
        FILES => "@CLEAN_FILES"
    },
    'dist'         => {PREOP=>('rm -f README; '.
                              'pod2text -80 < AuthCookie.pm > README; '.
                              'cp -f README $(DISTNAME)-$(VERSION);')}
);

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

sub build_prepare {
    my $mp_version = shift;

    my $outfile = 'AuthCookie.pm';

    my $infile = "AuthCookie.pm.mp${mp_version}";

    die "whoops, $infile doesnt exist!" unless -f $infile;

    # remove old copy of the file if its already there.
    if (-f $outfile) {
        unlink $outfile or die "unlink($outfile): $!";
    }

    # copy source file to the outfile
    require File::Copy;
    File::Copy::copy($infile, $outfile);

    push @CLEAN_FILES, 'AuthCookie.pm';
}

sub mod_perl_version {
    eval {
        require mod_perl
    };
    if ($@) {
        die "Can't find mod_perl installed: $@\n";
    }

    # version 3 does not exist yet, but we check here for sanity.
    if ($mod_perl::VERSION >= 3) {
        die "mod_perl version $mod_perl::VERSION is not supported\n";
    }
    elsif ($mod_perl::VERSION >= 1.99) {
        return 2;
    }
    elsif ($mod_perl::VERSION >= 1.0) {
        return 1;
    }
    else {
        die "mod_perl version $mod_perl::VERSION is not supported\n";
    }
}
