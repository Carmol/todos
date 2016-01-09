#!/usr/bin/env perl
#
# We need to bring a lot more, here
#
# This can only be considered a start, but nothing more.

use Test;
BEGIN { plan tests => 3 }

ok(1);

$reply = 1;
@reply = 1;
ok($reply / 3);
ok(@reply);
