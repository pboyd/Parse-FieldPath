use strict;
use warnings;

use Test::More tests => 9;
use Test::Deep;

use Parse::FieldPath qw/build_tree/;

cmp_deeply( build_tree('a'), { a => {} } );
cmp_deeply( build_tree('a,b'), { a => {}, b => {} } );
cmp_deeply( build_tree('a(b)'),   { a => { b => {} } } );
cmp_deeply( build_tree('a(b,c)'), { a => { b => {}, c => {} } } );
cmp_deeply( build_tree('a/b'),    { a => { b => {} } } );
cmp_deeply( build_tree('a/b/c'),    { a => { b => { c   => {} } } } );
cmp_deeply( build_tree('a/b(c,d)'), { a => { b => { c   => {}, d => {} } } } );
cmp_deeply( build_tree('a/b(c,d/e)'), { a => { b => { c   => {}, d => { e => {} } } } } );
cmp_deeply( build_tree('a/b/*'),    { a => { b => { '*' => {} } } } );
