package Apache2_4::AuthCookie;

use strict;
use base 'Apache2::AuthCookie::Base';
use Apache::AuthCookie::Autobox;
use Apache2::Log;
use Apache2::Const -compile => qw(AUTHZ_GRANTED AUTHZ_DENIED AUTHZ_DENIED_NO_USER);

# You really do not need this provider at all.  This provides an implementation
# for "Require user ..." directives, that is compatible with mod_authz_core
# (with the exception that expressions are not supported).  You should really
# just let mod_authz_core be your "user" authz provider.  Nevertheless, due to
# the fact that AuthCookie was released for Apache 2.4 with documentation that
# shows this is needed, we leave this implementation for backwards
# compatibility.
sub authz_handler  {
    my ($auth_type, $r, $requires) = @_;

    my $user = $r->user;

    if ($user->is_blank) {
        # user is not yet authenticated
        return Apache2::Const::AUTHZ_DENIED_NO_USER;
    }

    if ($requires->is_blank) {
        $r->server->log_error(q[Your 'Require user ...' config does not specify any users]);
        return Apache2::Const::AUTHZ_DENIED;
    }

    my $debug = $r->dir_config("AuthCookieDebug") || 0;

    $r->server->log_error("authz user=$user type=$auth_type req=$requires") if $debug >=3;

    for my $valid_user (split /\s+/, $requires) {
        if ($user eq $valid_user) {
            return Apache2::Const::AUTHZ_GRANTED;
        }
    }

    # log a message similar to mod_authz_user
    $r->log->debug(sprintf
        q[access to %s failed, reason: user '%s' does not meet 'require'ments for a ].
        q[user to be allowed access], $r->uri, $r->user);

    return Apache2::Const::AUTHZ_DENIED;
}

1;
