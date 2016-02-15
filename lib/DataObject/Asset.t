#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use lib 'lib';

use Data::Dumper;
use DataObject::Asset;
use Test::More tests => 4;

my $asset = DataObject::Asset->new( { 
   uri => 'http://www.example.com',
   name => 'I have a name',
} );

is($asset->uri, 'http://www.example.com', 'set and retrieved uri');
is($asset->name, 'I have a name', 'name set');

$asset->name( 'assetname' );

is($asset->name, 'assetname', 'set and retrieved name');

is_deeply($asset->hashify, 
   { uri => 'http://www.example.com', name => 'assetname' },
   'can hashify ok');

