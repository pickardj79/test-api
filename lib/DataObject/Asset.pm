package DataObject::Asset;

use base qw(DataObject);

use strict;
use warnings FATAL => 'all';

# Data model for Assets

# Fields
# uri - uri to retrieve actual asset
# name - name of asset

sub required_fields { [ qw(name uri) ] };

# accessors
sub uri {
   my ($self, $val) = @_;

   if (@_ == 2) {
      $self->{uri} = $val;
   }

   return $self->{uri};
}

sub name {
   my ($self, $val) = @_;

   if (@_ == 2) {
      $self->{name} = $val;
   }

   return $self->{name};
}

1;
