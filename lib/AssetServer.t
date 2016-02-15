#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use lib 'lib';

use AssetServer; 
use Data::Dumper;
use Encode;
use HTTPMessage::Request;
use HTTPMessage::Response;
use Test::More tests => 4;

my $asset_api = AssetServer->new();

is($asset_api->process_request(),
   HTTPMessage::Response->new( { status_code => 400 } )->as_string,
   'no request response as bad' );
