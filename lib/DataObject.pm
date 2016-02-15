package DataObject;

use strict;
use warnings FATAL => 'all';

# Baseclass / interface for datamodel classes

# list of fields that musts be defined to instantiate an object of the subclass
sub required_fields { "Virtural sub, defined in subclass" }

sub new {
   my ($class, $args) = @_;

   my $self = bless {}, $class;

   # initialize properties
   foreach my $key ( keys %{ $args || {} } ) {
      $self->$key( $args->{$key} );
   }

   # check for required fields
   foreach my $required ( @{$self->required_fields} ) {
      die "$required required"
         unless defined $self->$required;
   }

   return $self;
}

sub hashify {
   my ($self) = @_;

   return { %$self };
}

1;
