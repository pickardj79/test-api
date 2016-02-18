#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use lib 'lib';

use AssetAPI;
use CGI::Util qw(escape);
use Data::Dumper;
use Test::More tests => 3;

my $asset1      = { name => 'Ms. Swift', uri => 'myorg:://users/tswift' };
my $asset1_name = escape( $asset1->{name} );
my $asset1_uri  = escape( $asset1->{uri} );

my $note1 = { note => 'Middle name: Alison' };
my $note2 = { note => 'DOB: Dec 13, 1989' };

subtest 'basic functionality' => \&test_basic_functionality;
subtest '404 errors' => \&test_404_responses;
subtest '400 errors' => \&test_400_responses;

sub test_basic_functionality {
   plan tests => 38;

   my $api = AssetAPI->new();

   # format of @tests:
   # [ method, uri, body, expected return code, expected return body ]
   my @tests = (
      [ 'GET', '/assets', undef, 200, [] ],
      [ 'GET', '/assets?', undef, 200, [] ],
      [ 'POST', '/assets', $asset1, 201, { id => 2 } ],
      [ 'POST', '/assets', $asset1, 409,
         { error => "asset with name '$asset1->{name}' already exists" }
      ],
      [ 'GET', '/assets',   undef, 200, [ { %$asset1, id => 2 } ] ],
      [ 'GET', '/assets/2', undef, 200, [ { %$asset1, id => 2 } ] ],
      [ 'GET', '/assets/2/notes', undef, 200, [] ],
      [ 'POST', '/assets/2/notes', $note1, 201, { id => 2 } ],
      [ 'GET', '/assets/2/notes', undef, 200, [ { %$note1, assetid => 2 } ] ],
      [ 'GET', "/assets?asset_name=$asset1_name&",
         undef, 200, [ { %$asset1, id => 2 } ]
      ],
      [ 'GET', "/assets?asset_name=$asset1_name",
         undef, 200, [ { %$asset1, id => 2 } ]
      ],
      [ 'GET', "/assets?asset_uri=$asset1_uri",
         undef, 200, [ { %$asset1, id => 2 } ]
      ],
      [ 'GET', "/notes?asset_uri=$asset1_uri",
         undef, 200, [ { %$note1, assetid => 2 } ]
      ],
      [ 'POST', '/assets/2/notes', $note2, 201, { id => 3 } ],
      [ 'GET', '/assets/2/notes', undef, 200,
         [ { %$note2, assetid => 2 }, { %$note1, assetid => 2 } ]
      ],
      [ 'DELETE', '/assets/2', undef, 204, ],
      [ 'GET', '/assets', undef, 200, [] ],
      [ 'POST', '/assets', $asset1, 201, { id => 3 } ],
      [ 'GET', '/assets/3/notes', undef, 200, [] ],
   );

   foreach my $test (@tests) {
      my ( $method, $uri, $request_body, $exp_code, $exp_body ) = @$test;

      my ( $code, $body ) = $api->process_request( $method, $uri, $request_body );
      is( $code, $exp_code, "code for $method $uri" )
         || print Dumper $code;
      is_deeply( $body, $exp_body, "body for $method $uri" )
         || print Dumper $body;
   }
}

sub test_404_responses {
   plan tests => 12;

   my $api = AssetAPI->new();
   
   # [ method, uri, body, regexp for expected error message]
   # assumed that message body is hash ref with error key;
   # assumed that return code is 404
   my @err_tests = (
      [ 'GET', '/assets/3', undef, qr/^Could not find asset with assetid '3'/ ],
      [ 'GET', '/notes?asset_name=', undef, qr/Could not find asset with asset_name/ ],
      [  'GET', "/assets?asset_uri=not_an_asset",
         undef, qr/with asset_uri = 'not_an_asset'/
      ],
      [ 'GET', '/assets/3/notes', undef, qr/^Could not find asset with assetid '3'/ ],
      [ 'POST', '/assets/3/notes', {}, qr/^Could not find asset with assetid '3'/ ],
      [ 'DELETE', '/assets/3', undef, qr/^Could not find asset with assetid '3'/ ],
   );
   
   run_error_tests($api, \@err_tests, 404);
}

sub test_400_responses {
   plan tests => 40;
   
   my $api = AssetAPI->new();
   my ( $code, $body ) = $api->process_request( 'POST', '/assets', $asset1 );

   is($code, 201, 'created asset okay');
   is_deeply($body, { id => 2 }, 'created response body');

   # [ method, uri, body, regexp for expected error message]
   # assumed that message body is hash ref with error key;
   # assumed that return code is 404
   my @err_tests = (
      [ 'PATCH', '/assets/3', undef, qr/unsupported HTTP method/ ],
      [ 'GET', '/asset/3', undef, qr/path must be of form/ ],
      [ 'GET', '/assets&', undef, qr/path must be of form/ ],
      [ 'GET', '/assets/3/note', undef, qr/path must be of form/ ],
      [ 'GET', '/assets/3/notes/4', undef, qr/path must be of form/ ],
      [ 'GET', '/', undef, qr/path must be of form/ ],
      [ 'GET', '/', undef, qr/path must be of form/ ],
      [ 'GET', '/assets/3?key=val', undef, qr/cannot specify an asset id and an asset query param/ ],
      [ 'GET', '/notes', undef, qr/query param required for \/notes request/ ],
      [ 'GET', '/assets?key=val&key2=val2', undef, qr/only one query param allowed/ ],
      [ 'GET', '/assets?key=val', undef, qr/allowed query params are/ ],
      [ 'GET', '/assets', {}, qr/Cannot use GET with a message body/ ],
      [ 'POST', '/assets', undef, qr/missing message body/ ],
      [ 'POST', '/assets', {}, qr/badly-formed create asset request/ ],
      [ 'POST', '/assets/2', {}, qr/cannot specify an assetid/ ],
      [ 'POST', '/assets/2/notes', {}, qr/badly-formed create note request/ ],
      [ 'DELETE', '/assets/2/notes', undef, qr/cannot delete notes/ ],
      [ 'DELETE', '/assets', undef, qr/assetid required for delete/ ],
      [ 'DELETE', '/assets/2', {}, qr/Cannot use DELETE with a message body/ ],
   ); 
   run_error_tests($api, \@err_tests, 400);
}

sub run_error_tests {
   my ($api, $tests, $exp_code) = @_;

   # $tests is an arrayref of arrayrefs. Each arrayref is of the form:
   # [ method, uri, body, regexp for expected error message]
   # runs two tests for each arrayref in the $tests arrayref
   foreach my $err_test (@$tests) {
      my ( $method, $uri, $request_body, $body_regexp ) = @$err_test;

      my ( $code, $body ) = $api->process_request( $method, $uri, $request_body );
      is( $code, $exp_code, "error code for $method $uri" )
         || print Dumper $code;
      like( $body->{error}, $body_regexp, "error message for $method $uri" )
         || print Dumper $body;
   }
}

