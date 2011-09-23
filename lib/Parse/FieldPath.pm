package Parse::FieldPath;

# ABSTRACT: Perl module to extract fields from objects 

use strict;
use warnings;

use Exporter qw/import unimport/;
our @EXPORT_OK = qw/build_tree extract_fields/;

use Scalar::Util;
use Carp;

use Parse::FieldPath::Parser;

sub extract_fields {
    my ($obj, $field_path) = @_;

    croak "extract_fields needs an object" unless Scalar::Util::blessed($obj);

    my $tree = _build_tree($field_path);
    return _fields_from_object($obj, $tree);
}

sub _build_tree {
    my ($field_path) = @_;
    my $parser = Parse::FieldPath::Parser->new();
    return $parser->parse($field_path);
}

sub _fields_from_object {
    my ($obj, $tree) = @_;

    my %fields;
    for my $field (keys %$tree) {
        my $branch = $tree->{$field};
        my $value = $obj->$field;
        if (Scalar::Util::blessed($value)) {

            # Treat a/b/* just like a/b
            delete $branch->{'*'} if (exists $branch->{'*'});

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

=head1 BUGS / LIMITATIONS

=over 4

=item Doesn't support arrays currently

=item Needs more callbacks

=item Assumes that objects are blessed hashrefs (which isn't necessarily true)

=back

=head1 AUTHOR

Paul Boyd <pboyd@dev3l.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Paul Boyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
