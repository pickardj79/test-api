package DataObject::AssetNote;

use base qw(DataObject);

use strict;
use warnings FATAL => 'all';

# Data model for Notes on Assets

# Fields
# assetid - id of the asset this note applies to
# note - text of the note

sub required_fields { [ qw(assetid note) ] };

# accessors
sub assetid {
   my ($self, $val) = @_;

   if (@_ == 2) {
      $self->{assetid} = $val;
   }

   return $self->{assetid};
}

sub note {
   my ($self, $val) = @_;

   if (@_ == 2) {
      $self->{note} = $val;
   }

   return $self->{note};
}

1;
