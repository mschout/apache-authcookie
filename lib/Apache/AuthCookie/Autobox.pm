package Apache::AuthCookie::Autobox;

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

sub is_blank {
    return defined $_[0] && ($_[0] =~ /\S/) ? 0 : 1;
}

1;

__END__

=head1 SYNOPSIS

 Internal Use Only!

=head1 DESCRIPTION

This module provides autobox extensions for AuthCookie

