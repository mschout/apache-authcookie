package Apache2::AuthCookie::Util;

use Apache2::URI;

sub unescape_uri {
    my $string = shift;

    Apache2::URI::unescape_url($string);
    $string =~ tr/+/ /;

    return $string;
}

1;

__END__

=head1 NAME

Apache2::AuthCookie::Util - Internal utilities used by Apache2::AuthCookie

=head1 SYNOPSIS

none

=head1 DESCRIPTION

no public subroutines

=head1 SEE ALSO

L<Apache2::AuthCookie>
