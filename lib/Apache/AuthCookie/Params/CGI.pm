package Apache::AuthCookie::Params::CGI;
$Apache::AuthCookie::Params::CGI::VERSION = '3.23';
# ABSTRACT: Internal CGI Params Subclass

use strict;
use warnings;
use vars qw(@ISA);
use CGI;

@ISA = qw(CGI);

sub param {
    my $self = shift;

    # when CGI.pm introduced multi_param, you are expected to use it whenever
    # you expect a list response.  AuthCookie internally always expects a list
    # response, so use multi_param if it is available.
    local $CGI::LIST_CONTEXT_WARN = 0 if defined $CGI::LIST_CONTEXT_WARN;

    return $self->SUPER::param(@_);
}

1;

__END__

=pod

=head1 NAME

Apache::AuthCookie::Params::CGI - Internal CGI Params Subclass

=head1 VERSION

version 3.23

=head1 SYNOPSIS

 Internal Use Only!

=head1 DESCRIPTION

This is a wrapper class for CGI.pm for CGI.pm mode param processing.

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
