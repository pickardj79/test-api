package Datastore::Memory;

use base qw(Datastore);

use strict;
use warnings FATAL => 'all';

use Scalar::Util qw(blessed);

# Fields
# _datastore - hashref of id => data,
#    data can be of any type, but only objects can be indexed (see below)
# _next_id - int of the next id to assign
# _indexes - stores indexes of field value to object ids
#    is a hashref, keyed on the field name, 
#      value is a hashref that has keys of the indexed value
#      value of that is a hashref with keys of object ids, value is unused
#    field name is the name of the sub of the stored object that returns the
#      value that should be indexed

sub new {
   my ($class) = @_;

   my $self = bless {}, $class;
   $self->_datastore( {} );
   $self->_next_id(1);
   $self->_indexes( {} );

   return $self;
}

sub add_index {
   my ( $self, $fieldname ) = @_;

   die "not implemented to add indexes to existing data"
      if keys %{ $self->_datastore };

   $self->_indexes->{$fieldname} = {};
}

sub retrieve {
   my ( $self, $id ) = @_;

   return $self->_datastore->{$id};
}

sub retrieve_all {
   my ($self) = @_;
   return $self->_datastore;
}

sub insert {
   my ( $self, $data ) = @_;

   $self->_increment_next_id;
   my $id = $self->_next_id;

   $self->_datastore->{$id} = $data;

   $self->_add_index_values( $id, $data );

   return $id;
}

sub replace {
   my ( $self, $id, $data ) = @_;

   my $old_data = $self->_datastore->{$id};
   $self->_delete_index_values( $id, $old_data );

   $self->_datastore->{$id} = $data;

   $self->_add_index_values( $id, $data );

   return;
}

sub delete {
   my ( $self, $id ) = @_;

   my $data = delete $self->_datastore->{$id};
   $self->_delete_index_values( $id, $data );
   return;
}

# searches in the $index_field index for the $indexed_value, returns array ref
#  of all ids found in the index for the indexed_value
sub get_ids_by_index {
   my ( $self, $indexed_value, $indexed_field ) = @_;

   die "No index named $indexed_field"
      if !$self->_indexes->{$indexed_field};
   return [] unless exists $self->_indexes->{$indexed_field}->{$indexed_value};
   return [ keys %{ $self->_indexes->{$indexed_field}->{$indexed_value} } ];
}

sub _increment_next_id {
   my ($self) = @_;

   $self->_next_id( $self->_next_id + 1 );

   # avoid collisions
   $self->_increment_next_id
      if $self->retrieve( $self->_next_id );

   return;
}

# deletes from all indexes the keys associated with each key in $data
sub _delete_index_values {
   my ( $self, $id, $data ) = @_;

   return unless keys %{$self->_indexes};
   
   die 'Cannot index $data that is not an object'
      unless ref $data && blessed $data;
   
INDEX:
   while ( my ( $idx_name, $index ) = each %{ $self->_indexes } ) {
      next INDEX
         unless defined $data->$idx_name;
      
      delete $index->{ $data->$idx_name }->{$id};

      delete $index->{ $data->$idx_name }
         if !keys %{ $index->{ $data->$idx_name } };
   }
}

sub _add_index_values {
   my ( $self, $id, $data ) = @_;

   return unless keys %{$self->_indexes};

   die 'Cannot index $data that is not an object'
      unless ref $data && blessed $data;

INDEX:
   while ( my ( $idx_name, $index ) = each %{ $self->_indexes } ) {
      next INDEX
         unless defined $data->$idx_name;

      $index->{ $data->$idx_name } ||= {};

      $index->{ $data->$idx_name }->{$id} = 1;
   }
}

# accessors
sub _datastore {
   my ( $self, $val ) = @_;

   if ( @_ == 2 ) {
      $self->{datastore} = $val;
   }

   return $self->{datastore};
}

sub _next_id {
   my ( $self, $val ) = @_;

   if ( @_ == 2 ) {
      $self->{next_id} = $val;
   }

   return $self->{next_id};
}

sub _indexes {
   my ( $self, $val ) = @_;

   if ( @_ == 2 ) {
      $self->{_indexes} = $val;
   }

   return $self->{_indexes};
}

1;
