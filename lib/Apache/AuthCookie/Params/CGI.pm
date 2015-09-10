package Apache::AuthCookie::Params::CGI;

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

=head1 SYNOPSIS

 Internal Use Only!

=head1 DESCRIPTION

This is a wrapper class for CGI.pm for CGI.pm mode param processing.

