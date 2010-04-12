# WARNING: this file is generated, do not edit
# 01: /home/mschout/dev/perls/5.8.8/lib/perl5/site_perl/arch/Apache/TestConfig.pm:923
# 02: /home/mschout/dev/perls/5.8.8/lib/perl5/site_perl/arch/Apache/TestConfig.pm:941
# 03: /home/mschout/dev/perls/5.8.8/lib/perl5/site_perl/arch/Apache/TestConfigPerl.pm:206
# 04: /home/mschout/dev/perls/5.8.8/lib/perl5/site_perl/arch/Apache/TestConfig.pm:609
# 05: /home/mschout/dev/perls/5.8.8/lib/perl5/site_perl/arch/Apache/TestConfig.pm:624
# 06: /home/mschout/dev/perls/5.8.8/lib/perl5/site_perl/arch/Apache/TestConfig.pm:1558
# 07: /home/mschout/dev/perls/5.8.8/lib/perl5/site_perl/arch/Apache/TestRun.pm:506
# 08: /home/mschout/dev/perls/5.8.8/lib/perl5/site_perl/arch/Apache/TestRunPerl.pm:84
# 09: /home/mschout/dev/perls/5.8.8/lib/perl5/site_perl/arch/Apache/TestRun.pm:725
# 10: /home/mschout/dev/perls/5.8.8/lib/perl5/site_perl/arch/Apache/TestRun.pm:725
# 11: /home/mschout/dev/apache-authcookie/t/TEST:24

BEGIN {
    use lib '/home/mschout/dev/apache-authcookie/t';
    for my $file (qw(modperl_inc.pl modperl_extra.pl)) {
        eval { require "conf/$file" } or
            die if grep { -e "$_/conf/$file" } @INC;
    }
}

1;
