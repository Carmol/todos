#!/usr/bin/env perl
#
# We need to bring a lot more, here

use Test;
BEGIN { plan tests => 3 }

ok(1);

$reply = 1;
@reply = 1;
ok($reply / 3);
ok(@reply);
