package Apache::AuthCookie::Params::Base;

# ABSTRACT: Internal CGI AuthCookie Params Base Class

use strict;
use warnings;
use Class::Load qw(load_class);
use Apache::AuthCookie::Util qw(is_blank);

=method new($r)

Constructor.  This will generate either an internal
L<Apache::AuthCookie::Params::CGI> object, or, if available, use libapreq2.
Note that libapreq2 will not be used if you turned on C<Encoding> support
because libapreq2 does not have any support for unicode.

=cut

sub new {
    my ($class, $r) = @_;

    my $debug = $r->dir_config("AuthCookieDebug") || 0;

    # use existing params object if possible
    my $obj = $r->pnotes($class);
    if (defined $obj) {
        return $obj;
    }

    # if an encoding is in effect, then always use the ::CGI interface because
    # libapreq has no support for UTF-8
    my $auth_name = $r->auth_name;

    if (!is_blank($r->dir_config("${auth_name}Encoding"))) {
        $obj = __PACKAGE__->_new_instance($r);
    }
    else {
        $obj = $class->_new_instance($r);
    }

    $r->pnotes($class, $obj);

    return $obj;
}

sub _new_instance {
    my ($self, $r) = @_;

    load_class('Apache::AuthCookie::Params::CGI');

    return Apache::AuthCookie::Params::CGI->new($r);
}

1;

__END__

=head1 SYNOPSIS

 Internal Use Only!

=head1 DESCRIPTION

This is the base class for AuthCookie Params drivers.

