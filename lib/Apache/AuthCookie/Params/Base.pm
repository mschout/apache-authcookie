package Apache::AuthCookie::Params::Base;
$Apache::AuthCookie::Params::Base::VERSION = '3.23';
# ABSTRACT: Internal CGI AuthCookie Params Base Class

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

    load_class('Apache::AuthCookie::Params::CGI');

    return Apache::AuthCookie::Params::CGI->new($init);
}

1;

__END__

=pod

=head1 NAME

Apache::AuthCookie::Params::Base - Internal CGI AuthCookie Params Base Class

=head1 VERSION

version 3.23

=head1 SYNOPSIS

 Internal Use Only!

=head1 DESCRIPTION

This is the base class for AuthCookie Params drivers.

=head1 SOURCE

The development version is on github at L<http://github.com/mschout/apache-authcookie>
and may be cloned from L<git://github.com/mschout/apache-authcookie.git>

=head1 BUGS

Please report any bugs or feature requests to bug-apache-authcookie@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Apache-AuthCookie

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2000 by Ken Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
