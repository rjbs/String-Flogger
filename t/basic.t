#!perl
use strict;
use warnings;
use Test::More tests => 4;
use String::Flogger qw(flog);

is(
  flog([ 'foo %s bar', undef ]),
  'foo {{null}} bar',
  "%s <- undef",
);

is(
  flog([ 'foo %s bar', \undef ]),
  'foo ref({{null}}) bar',
  "%s <- \\undef",
);

is(
  flog([ 'foo %s bar', \1 ]),
  'foo ref(1) bar',
  "%s <- \\1",
);

is(
  flog([ 'foo %s bar', \\1 ]),
  'foo ref(ref(1)) bar',
  "%s <- \\\\1",
);

