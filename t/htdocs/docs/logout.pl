use strict;

my $r = Apache->request;
my $auth_type = $r->auth_type;

# Delete the cookie, etc.
$auth_type->logout($r);
$r->content_type("text/html");
$r->status(200);
$r->send_http_header;

print <<EOF;
<HTML>
<HEAD><TITLE>Logged Out</TITLE></HEAD>
<BODY>
<P>You have been logged out and the cookie deleted from you browser.</P>
<P><A HREF="protected/get_me.html">Go ahead and try it again.</A></P>
</BODY>
</HTML>
EOF
