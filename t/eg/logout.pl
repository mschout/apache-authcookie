use strict;

my $r = Apache->request;
my $auth_type = $r->auth_type;
my $auth_name = $r->auth_name;
my $path = $r->dir_config($auth_name . "Path");
$r->no_cache(1);
$r->status(200);
$r->header_out("Pragma", "no-cache");
$r->header_out("Set-Cookie",$auth_type . "_" . $auth_name . "=; path=" .
    $path . "; expires=Mon, 21-May-1971 00:00:00 GMT");
$r->content_type("text/html");
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
