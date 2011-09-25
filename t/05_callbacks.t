use strict;
use warnings;

use Test::More tests => 5;
use Test::Deep;
use Test::MockObject;

use Parse::FieldPath qw/extract_fields/;

my $obj = Test::MockObject->new();
$obj->set_always( a => 'x' );
$obj->set_always( b => 'y' );

my $obj2 = Test::MockObject->new();
$obj2->set_always( c => 'z' );

$obj->set_always( x => $obj2 );
$obj->set_always(field_list => ['a', 'b', 'x']);

$obj2->set_always(field_list => undef);
eval {
    extract_fields($obj, 'x');
};
like($@, qr/\QExpected $obj2->field_list to return an arrayref\E/, 'should die when field_list doesn\'t return an arrayref');

my $field_list_params;
$obj2->mock('field_list', sub {
    shift;
    $field_list_params = \@_;
    return ['c'];
});

extract_fields($obj, 'x');
ok(defined $field_list_params, 'field_list should be called on the object');
cmp_deeply( $field_list_params, [], 'field_list should not be passed any params');

cmp_deeply( extract_fields( $obj, 'x' ), { x => { c => 'z' } } );
cmp_deeply( extract_fields( $obj, 'x/*' ), { x => { c => 'z' } } );
