package Parse::FieldPath;

# ABSTRACT: Perl module to extract fields from objects

use strict;
use warnings;

use Exporter qw/import unimport/;
our @EXPORT_OK = qw/build_tree extract_fields/;

use Scalar::Util;
use Carp;

use Parse::FieldPath::Parser;

# Maximum number of times to allow _extract to recurse.
use constant RECURSION_LIMIT => 512;

sub extract_fields {
    my ( $obj, $field_path ) = @_;

    croak "extract_fields needs an object" unless Scalar::Util::blessed($obj);

    my $tree = _build_tree($field_path);
    return _extract( $obj, $tree );
}

sub _build_tree {
    my ($field_path) = @_;
    my $parser = Parse::FieldPath::Parser->new();
    return $parser->parse($field_path);
}

sub _extract {
    my ( $obj, $tree, $recurse_count ) = @_;

    $recurse_count ||= 0;
    $recurse_count++;
    die "Maximum recursion limit reached" if $recurse_count >= RECURSION_LIMIT;

    my %fields;
    for my $field ( keys %$tree ) {
        my $branch = $tree->{$field};
        my $value  = $obj->$field;
        if ( Scalar::Util::blessed($value) ) {

            # Treat a/b/* just like a/b
            delete $branch->{'*'} if ( exists $branch->{'*'} );

            if (%$branch) {
                $fields{$field} = _extract( $value, $branch, $recurse_count );
            }
            else {

                # We've got an object, but not a list of fields. Get everything.
                my $all_fields = [];
                $all_fields = $value->field_list()
                  if ( $value->can('field_list') );

                die "Expected $value->field_list to return an arrayref"
                  unless Scalar::Util::reftype($all_fields)
                      && Scalar::Util::reftype($all_fields) eq 'ARRAY';

                for my $sub_field (@$all_fields) {
                    my %sub_branch = ( $sub_field => {}, );
                    $fields{$field}->{$sub_field} =
                      _extract( $value, \%sub_branch, $recurse_count )
                      ->{$sub_field};
                }
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

=pod

=head1 NAME

Parse::FieldPath

=head1 ABSTRACT

Parses an XPath inspired field list and extracts those fields from an object
hierarchy.

Based on the "fields" parameter for the Google+ API:
http://developers.google.com/+/api/

=head1 SYNOPSIS

Say you have an object, with some sub-objects, that's initialized like this:

  my $cow = Cow->new();
  $cow->color("black and white");
  $cow->tail(Cow::Tail->new(floppy => 1));
  $cow->mouth(Cow::Tounge->new(
    tounge => Cow::Tounge->new,
    teeth  => Cow::Teeth->new,
  );

And you want a hash containing some of those fields (perhaps to pass to
JSON::XS, or something). Then you can do this:

  use Parse::FieldPath qw/extract_fields/;

  my $cow_hash = extract_fields($cow, "color,tail/floppy");
  # $cow_hash is now:
  # {
  #   color => 'black and white',
  #   tail  => {
  #     floppy => 1,
  #   }
  # }

=head1 SYNTAX

(To be written)

=head1 FUNCTIONS

=over 4

=item B<extract_fields ($object, $field_path)>

Parses the field_path and returns the fields requested from $object.

=back

=head1 CONTRIBUTING

If your interested in fixing a bug, adding a feature or bashing the code, look
on GitHub: https://github.com/pboyd/Parse-FieldPath

=head1 AUTHOR

Paul Boyd <pboyd@dev3l.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Paul Boyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
