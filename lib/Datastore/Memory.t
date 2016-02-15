#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use lib 'lib';

use Datastore::Memory;
use Test::More tests => 2;

my $TEST_PACKAGE = build_test_package();

subtest 'basic retrieve/replace/create/delete' => \&test_basic_functionality;
#subtest 'unique indexing'                      => \&test_unique_indexing;
subtest 'indexing'                             => \&test_indexing;

sub test_basic_functionality {
   plan tests => 9;
   my $store1 = Datastore::Memory->new();
   my $store2 = Datastore::Memory->new();

   $store1->replace(1, 'bar1');
   $store2->replace(1, 'bar2');

   is($store1->retrieve(1), 'bar1', 'stored into 1'); 
   is($store2->retrieve(1), 'bar2', 'store2 is distinct from store1'); 

   $store1->replace(2, 'bar2');
   $store1->replace(3, 'bar3');

   my $id = $store1->insert('should be key 4');

   is($id, 4, 'incremented next id');
   is($store1->retrieve(4), 'should be key 4', 'inserted into key 4');

   is($store2->insert('insert into 2'), 2, 'insert into store2 distinct from store1');

   is_deeply($store1->retrieve_all,
      { 1 => 'bar1', 2 => 'bar2', 3 => 'bar3', 4 => 'should be key 4' }, 'retrieve all' );

   $store1->delete(2);
   $store1->delete(3);
   $store1->delete(4);

   is_deeply($store1->retrieve_all, { 1 => 'bar1' }, 'delete removed keys' );
   is($store1->retrieve(2), undef, 'delete removed key 2');
   is_deeply($store1->retrieve_all, { 1 => 'bar1' }, 'retrieve on unknown did not make a key' );

   # test that deleting an unknown key doesn't die
   $store1->delete(2);
}

sub test_unique_indexing {
   plan tests => 7;
   
   my $store = Datastore::Memory->new();
   $store->add_unique_index('field1', 'unused index');
   $store->add_unique_index('field2');

   my $val1_id = $store->insert( { field1 => 'val1' } ); 
   my $val2_id = $store->insert( { field2 => 'val2' } ); 

   is($store->get_id_by_unique_index('val1', 'field1'), $val1_id, 'got by index 1');
   is($store->get_id_by_unique_index('val2', 'field1'), undef, 'got no id for index 1');
   is($store->get_id_by_unique_index('val2', 'field2'), $val2_id, 'got by index 2');

   $store->delete($val1_id);
   is($store->get_id_by_unique_index('val1', 'field1'), undef, 
      'index cleared after delete');

   $store->replace($val2_id, { field1 => 'data now in field1' } );
   is($store->get_id_by_unique_index('val2', 'field2'), undef, 
      'replace removed old index');
   is($store->get_id_by_unique_index('data now in field1', 'field1'), $val2_id,
      'replace added new index value');
   
   is_deeply($store->_unique_indexes, {
      'field1' => { 'data now in field1' => $val2_id },
      'field2' => {},
   }, 'indexes look good' );
}

sub test_indexing {
   plan tests => 7;
   
   my $store = Datastore::Memory->new();
   $store->add_index('field1', 'unused index');
   $store->add_index('field2');

   my $obj1 = $TEST_PACKAGE->new( { field1 => 'val1' } );
   my $obj2 = $TEST_PACKAGE->new( { field1 => 'val1' } );
   my $obj3 = $TEST_PACKAGE->new( { field2 => 'val2' } );
   my $val1_id = $store->insert( $obj1 ); 
   my $val2_id = $store->insert( $obj2 ); 
   my $val3_id = $store->insert( $obj3 );

   my @ids = sort @{$store->get_ids_by_index('val1', 'field1')};
   is_deeply(\@ids, [sort ($val1_id, $val2_id)], 'got by index 1');

   is_deeply($store->get_ids_by_index('val1', 'field2'), [], 'got no id for val1 in index2');
   is_deeply($store->get_ids_by_index('val2', 'field2'), [ $val3_id ], 'got by field2 index');

   $store->delete($val1_id);
   
   is_deeply($store->get_ids_by_index('val1', 'field1'), [$val2_id], 
      'got by field1 after delete');
   
   my $obj4 = $TEST_PACKAGE->new( { field1 => 'new value' } );
   
   $store->replace($val2_id, $obj4 );
   is_deeply($store->get_ids_by_index('val1', 'field1'), [], 
      'replace removed old indexed value');
   is_deeply($store->get_ids_by_index('new value', 'field1'), [$val2_id], 
      'replace added new indexed value');

   is_deeply($store->_indexes, {
      'field1' => { 'new value' => { $val2_id => 1} },
      'field2' => { 'val2' => { $val3_id => 1} },
   }, 'indexes look good' );
}

sub build_test_package {
   package TestObject;

   # fields: field1, field2
   sub new {
      my ($class, $args) = @_;

      return bless { %$args }, $class;
   }

   sub field1 {
      my ( $self, $val ) = @_;

      if ( @_ == 2 ) {
         $self->{field1} = $val;
      }

      return $self->{field1};
   }

   sub field2 {
      my ( $self, $val ) = @_;

      if ( @_ == 2 ) {
         $self->{field2} = $val;
      }

      return $self->{field2};
   }

   return "TestObject";
}


