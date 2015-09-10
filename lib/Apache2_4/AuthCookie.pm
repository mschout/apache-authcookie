package Apache2_4::AuthCookie;
$Apache2_4::AuthCookie::VERSION = '3.23';
use strict;
use base 'Apache2::AuthCookie::Base';
use Apache::AuthCookie::Autobox;
use Apache2::Const -compile => qw(AUTHZ_GRANTED AUTHZ_DENIED AUTHZ_DENIED_NO_USER);

sub authz_handler  {
    my ($auth_type, $r, @requires) = @_;

    return Apache2::Const::AUTHZ_DENIED unless @requires;

    my $debug = $r->dir_config("AuthCookieDebug") || 0;

    my $user = $r->user;

    $r->server->log_error("authz user=$user type=$auth_type req=@requires") if $debug >=3;

    if ($user->is_blank) {
        # user not yet authenticated
        $r->server->log_error("No user authenticated", $r->uri);
        return Apache2::Const::AUTHZ_DENIED_NO_USER;
    }

    foreach my $req (@requires) {
        $r->server->log_error("requirement := $req") if $debug >= 2;

        if (lc $req eq 'valid-user') {
            return Apache2::Const::AUTHZ_GRANTED;
        }

        return $req eq $user ? Apache2::Const::AUTHZ_GRANTED : Apache2::Const::AUTHZ_DENIED;
    }

    return Apache2::Const::AUTHZ_DENIED;
}

1;

__END__

=pod

=head1 NAME

Apache2_4::AuthCookie

=head1 VERSION

version 3.23

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
