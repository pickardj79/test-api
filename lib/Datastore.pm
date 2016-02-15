package Datastore;

use strict;
use warnings FATAL => 'all';

# Baseclass / Interface for classes that implement a datastore

# returns the data for an id, undef if id doesn't exist
sub retrieve     { 
   my ($self, $id) = @_;
   die "virtual sub - define in subclass" 
}

# returns a hashref of all data id => data 
sub retrieve_all { 
   my ($self) = @_;
   die "virtual sub - define in subclass" 
}

# inserts new data, making an id, returns id
sub insert { 
   my ($self, $data) = @_;
   die "virtual sub - define in subclass" 
}

# creates/replace the data for an id, no return
sub replace { 
   my ($self, $id, $data) = @_;
   die "virtual sub - define in subclass" 
}

# deletes the data for an id, no return. no-op if data doesn't exist
sub delete { 
   my ($self, $id) = @_;
   die "virtual sub - define in subclass"
}

# returns the id of data using the index specified by $index_name
sub getid_by_index {
   my ($self, $val, $index_name) = @_;
   die "virtual sub - define in subclass"
}

1;
