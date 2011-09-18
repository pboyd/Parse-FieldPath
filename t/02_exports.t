use strict;
use warnings;

use Test::More tests => 1;

use Parse::FieldPath qw/build_tree/;
can_ok( __PACKAGE__, 'build_tree' );
