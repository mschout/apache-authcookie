#!/usr/bin/env perl
#
# tests for Apache::AuthCookie::Autobox
#

use strict;
use Test::More tests => 8;

# don't use_ok, this needs to load at compile time.
use Apache::AuthCookie::Autobox;

ok ' '->is_blank;
ok ''->is_blank;
ok "\t"->is_blank;
ok "\n"->is_blank;
ok "\r\n"->is_blank;
ok undef->is_blank;
ok !0->is_blank;
ok !'a'->is_blank;

