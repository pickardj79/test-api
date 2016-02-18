package Datastore::Memory;

use base qw(Datastore);

use strict;
use warnings FATAL => 'all';

use Scalar::Util qw(blessed);

# In-memory datastore, uses autoincrement id for insert requests

# Fields
# _datastore - hashref of id => data,
#    data can be of any type, but only objects can be indexed (see below)
# _next_id - int of the next id to assign
# _indexes - stores indexes of field value to object ids
#    _indexes is a hashref, keyed on the name of the indexed field;
#      value is a hashref that has keys as values of the indexed field;
#      values of that is a hashref with keys of object ids, value is unused
#    field name is the name of the sub of the stored object that returns the
#      value that should be indexed, normally a field
#  example: 
#  _indexes = {
#     indexed_field_name1 => { value1 => { id1 => 1, id2 => 1 }, value2 => { id2 => 1 } },
#     indexed_field_name2 => { valuea => { id1 => 1 } },
#  }

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

# deletes from all indexes the ids associated with each indexed field in $data
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

      # remove the value of the indexed field if no more ids are indexed by it
      delete $index->{ $data->$idx_name }
         if !keys %{ $index->{ $data->$idx_name } };
   }
}

# adds $id to all indexed fields that have a value in $data
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
