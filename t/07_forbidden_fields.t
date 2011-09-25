use strict;
use warnings;

use Test::More tests => 2;
use Test::Deep;
use Test::MockObject;

use Parse::FieldPath qw/extract_fields/;

my $obj = Test::MockObject->new();
$obj->set_always( a => 'a' );
$obj->set_always( b => 'b' );
$obj->set_always( field_list => ['a'] );

cmp_deeply(extract_fields($obj, 'b'), {}, 'should not return fields that aren\'t in field_list()');
cmp_deeply(extract_fields($obj, 'a,b'), { a => 'a' }, 'should return valid field that are requested with invalid ones');
