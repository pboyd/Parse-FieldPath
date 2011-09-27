package Parse::FieldPath::Role;

use Moose::Role;
use Parse::FieldPath;

sub all_fields {
    my ($self) = @_;
    return [ grep { defined }
          map { $_->accessor || $_->reader } $self->meta->get_all_attributes ];
}

sub extract_fields {
    return Parse::FieldPath::extract_fields(@_);
}

1;
