use strict;

my $r = Apache->request;
my $auth_type = $r->auth_type;

# Delete the cookie, etc.
$r->content_type("text/html");
$r->status(200);
$r->send_http_header;

print $auth_type->key;
