package Parse::FieldPath;

use strict;
use warnings;

use Exporter qw/import unimport/;
our @EXPORT_OK = qw/build_tree/;

use Parse::RecDescent;

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

1;
