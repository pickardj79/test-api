#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use lib 'lib';

use DataObject::AssetNote;
use English qw(-no_match_vars);
use Test::More tests => 4;

eval {
   DataObject::AssetNote->new();
};
like($EVAL_ERROR, qr/assetid required/, 'died if not assetid');

my $init_params = 
   { assetid => 1234, note => 'I made a note!' };
my $assetnote = DataObject::AssetNote->new($init_params);

is( $assetnote->assetid, 1234, 'assetid set');
is( $assetnote->note, 'I made a note!', 'note set');

is_deeply( $assetnote->hashify, $init_params, 'hashified okay' ); 

