#!/usr/bin/perl

use strict;
my $r = Apache->request;

$r->status(200);
my $uri = $r->prev->uri;

my $form = <<HERE;
<HTML>
<HEAD>
<TITLE>Enter Login and Password</TITLE>
</HEAD>
<BODY onLoad="document.forms[0].credential_0.focus();">
<FORM METHOD="POST" ACTION="LOGIN">
<TABLE WIDTH=60% ALIGN=CENTER VALIGN=CENTER>
<TR><TD ALIGN=CENTER>
<H1>This is a secure document</H1>
</TD></TR>
<TR><TD ALIGN=LEFT>
<P>Please enter your login and password to authenticate.</P>
</TD>
<TR><TD>
<INPUT TYPE=hidden NAME=destination VALUE="$uri">

</TD></TR>
<TR><TD>
<TABLE ALIGN=CENTER>
<TR>
<TD ALIGN=RIGHT><B>Login:</B></TD>
<TD><INPUT TYPE="text" NAME="credential_0" SIZE=10 MAXLENGTH=10></TD>
</TR>
<TR>
<TD ALIGN=RIGHT><B>Password:</B></TD>
<TD><INPUT TYPE="password" NAME="credential_1" SIZE=8 MAXLENGTH=8></TD>
</TR>
<TR>
<TD COLSPAN=2 ALIGN=CENTER><INPUT TYPE="submit" VALUE="Continue"></TD>
</TR></TABLE>
</TD></TR></TABLE>
</FORM>
</BODY>
</HTML>
HERE

$r->no_cache(1);
my $x = length($form);
$r->content_type("text/html");
$r->header_out("Content-length","$x");
$r->header_out("Pragma", "no-cache");
$r->send_http_header;

$r->print ($form);
