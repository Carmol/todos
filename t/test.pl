#!/usr/bin/env perl

use Test;
BEGIN { plan tests => 3 }

ok(1);

$reply = 1;
@reply = 1;
ok($reply / 3);
ok(@reply);
