# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Apache::AuthCookie;
$loaded = 1;
print "ok 1\n";
print "\n";
print "Apache::AuthCookie requires runtime support from mod_perl that\n";
print "can not be simulated without running httpd. This test only verifies\n";
print "the syntax of the perl package.\n\n";
print "To verify that Apache::AuthCookie is working, install it and run\n";
print "it under mod_perl.\n\n";
print "Apache::AuthCookie requires that you enabled the following handlers\n";
print "when you compiled mod_perl:\n";
print "\tAuthen Handler\n";
print "\tAuthz Handler\n";
print "\tStacked Handlers\n";
print "\tMethod Handlers\n\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

