package Parse::FieldPath;

use strict;
use warnings;

use Exporter qw/import unimport/;
our @EXPORT_OK = qw/build_tree extract_fields/;

use Parse::RecDescent;
use Scalar::Util;
use Carp;

sub _parser {
    my $grammar = q{
        parse: fields /^\Z/
            {
                $return = $item[1];
            }

        fields: field(s /,/)
            {
                use Hash::Merge qw//;
                use List::Util qw//;
                $return = List::Util::reduce { Hash::Merge::merge($a, $b) } {}, @{$item[1]};
            }

        field: field_list | field_path | <error>

        field_name: /\w+/ | '*' | <error?>
        field_list: field_path '(' fields ')'
            {
                sub deepest {
                    my $hashref = shift;
                    return $hashref if scalar(keys %$hashref) == 0;
                    my $key = (keys %$hashref)[0];
                    return deepest($hashref->{$key});
                }
                my $deepest = deepest($item{field_path});
                $deepest->{$_} = $item{fields}->{$_} for keys %{$item{fields}};
                $return = $item{field_path};
            }

        # Matches "a/b", "a/b/c" or just "a"
        field_path: field_name(s /\//)
            {
                use List::Util qw//;

                # Turn qw/a b c/ into { a => { b => { c => {} } } }
                my $fields = {};
                List::Util::reduce { $a->{$b} = {} } $fields, @{$item{'field_name(s)'}};
                $return = $fields;
            }
    };
    return Parse::RecDescent->new($grammar);
}

sub build_tree {
    my ($field_path) = @_;
    my $parser = _parser;
    return $parser->parse($field_path);
}

sub extract_fields {
    my ($obj, $field_path) = @_;

    croak "extract_fields needs an object" unless Scalar::Util::blessed($obj);

    my $tree = build_tree($field_path);
    return _fields_from_object($obj, $tree);
}

sub _fields_from_object {
    my ($obj, $tree) = @_;

    my %fields;
    for my $field (keys %$tree) {
        my $branch = $tree->{$field};
        my $value = $obj->$field;
        if (Scalar::Util::blessed($value)) {
            if (%$branch) {
                $fields{$field} = _fields_from_object($value, $branch);
            }
            else {
                # We've got an object, but don't know which fields to grab.
                # FIXME: This is almost certainly the wrong thing to do. It should
                # figure out what the available fields are and only return those.
                $fields{$field} = {%$value};
            }
        }
        else {
            if (%$branch) {
                # Unblessed object, but a sub-object has been requested.
                # Setting it to undef, maybe an error should be thrown here
                # though?
                $fields{$field} = undef;
            }
            else {
                $fields{$field} = $value;
            }
        }
    }

    return \%fields;
}

1;
