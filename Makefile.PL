use ExtUtils::MakeMaker;
use File::Spec;

my @CLEAN_FILES = ();
my $mp_version = mod_perl_version();
build_prepare($mp_version);
test_prepare($mp_version);

test_configure();

my %makeconf = (
    'NAME'         => 'Apache::AuthCookie',
    'VERSION_FROM' => 'AuthCookie.pm',
    'PREREQ_PM'    => {
        'Apache::Test' => 1.09
    },
    'clean'        => {
        FILES => "@CLEAN_FILES"
    }
);

if ($mp_version == 2) {
    $makeconf->{PREREQ_PM}{mod_perl} = '1.9913';
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

    push @CLEAN_FILES, $outfile;
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
