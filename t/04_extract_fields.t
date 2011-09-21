use strict;
use warnings;

use Test::More tests => 10;
use Test::Deep;
use Test::MockObject;

use Parse::FieldPath qw/extract_fields/;

eval { extract_fields("") };
like( $@, qr/extract_fields needs an object/ );

my $obj = Test::MockObject->new();
$obj->{hash_key} = 1;
$obj->set_always( a => 'x' );
$obj->set_always( b => 'y' );
$obj->set_always( x => $obj );

cmp_deeply( extract_fields( $obj, 'a' ), { a => 'x' } );
cmp_deeply( extract_fields( $obj, 'a,b' ), { a => 'x', b => 'y' } );
cmp_deeply( extract_fields( $obj, 'x/a' ), { x => { a => 'x' } } );
cmp_deeply( extract_fields( $obj, 'x(a)' ), { x => { a => 'x' } } );
cmp_deeply( extract_fields( $obj, 'x(a,b)' ), { x => { a => 'x', b => 'y' } } );
cmp_deeply( extract_fields( $obj, 'a/x' ), { a => undef } );
cmp_deeply( extract_fields( $obj, 'x' ), { x => { hash_key => 1} } );

cmp_deeply( extract_fields( $obj, 'x/a,x/b' ), { x => { a => 'x', b => 'y' } } );
cmp_deeply( extract_fields( $obj, 'x/x/x/b' ), { x => { x => { x => { b => 'y' } } } } );
