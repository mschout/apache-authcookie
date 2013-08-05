package Apache24::AuthCookie;

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
