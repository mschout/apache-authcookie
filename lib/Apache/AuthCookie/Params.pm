package Apache::AuthCookie::Params;

# ABSTRACT: AuthCookie Params Driver for mod_perl 1.x

use strict;
use warnings;
use base 'Apache::AuthCookie::Params::Base';
use Class::Load qw(try_load_class);

sub _new_instance {
    my ($class, $r) = @_;

    my $debug = $r->dir_config('AuthCookieDebug') || 0;

    my $obj;

    if (try_load_class('Apache::Request')) {
        $r->server->log_error("params: using Apache::Request") if $debug >= 3;

        return Apache::Request->new($r);
    }
    else {
        $r->server->log_error("params: using CGI") if $debug >= 3;

        return $class->SUPER::_new_instance($r);
    }

    return;
}

1;

__END__

=head1 SYNOPSIS

 Internal Use Only!

=head1 DESCRIPTION

This class handles CGI form data for L<Apache::AuthCookie>.  It will try to use
L<Apache::Request> (from libapreq) if it is available.  If not, it will fall
back to use L<CGI>.

