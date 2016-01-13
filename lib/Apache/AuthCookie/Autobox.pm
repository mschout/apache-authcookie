package Apache::AuthCookie::Autobox;
$Apache::AuthCookie::Autobox::VERSION = '3.24';
# ABSTRACT: Autobox Extensions for AuthCookie

use strict;
use base 'autobox';

sub import {
    my $class = shift;

    $class->SUPER::import(
        SCALAR => __PACKAGE__ . '::Scalar',
        UNDEF  => __PACKAGE__ . '::Scalar');
}

package Apache::AuthCookie::Autobox::Scalar;
$Apache::AuthCookie::Autobox::Scalar::VERSION = '3.24';
sub is_blank {
    return defined $_[0] && ($_[0] =~ /\S/) ? 0 : 1;
}

1;

__END__

=pod

=head1 NAME

Apache::AuthCookie::Autobox - Autobox Extensions for AuthCookie

=head1 VERSION

version 3.24

=head1 SYNOPSIS

 Internal Use Only!

=head1 DESCRIPTION

This module provides autobox extensions for AuthCookie

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
