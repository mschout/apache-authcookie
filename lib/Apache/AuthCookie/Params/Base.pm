package Apache::AuthCookie::Params::Base;

# ABSTRACT: Interanal CGI AuthCookie Params Base Class

use strict;
use warnings;
use Class::Load qw(load_class);

sub new {
    my ($class, $r) = @_;

    my $debug = $r->dir_config("AuthCookieDebug") || 0;

    # use existing params object if possible
    my $obj = $r->pnotes($class);
    if (defined $obj) {
        return $obj;
    }

    $obj = $class->_new_instance($r);

    $r->pnotes($class, $obj);

    return $obj;
}

sub _cgi_new {
    my ($self, $init) = @_;

    load_class('CGI');

    return CGI->new($init);
}

1;

__END__

=head1 SYNOPSIS

 Internal Use Only!

=head1 DESCRIPTION

This is the base class for AuthCookie Params drivers.

