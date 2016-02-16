#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use lib 'lib';

use AssetServer; 
use Encode;
use HTTPMessage::Request;
use HTTPMessage::Response;
use Test::More tests => 6;

my $asset_api = AssetServer->new();

# test format:
# [method, uri, request body, expected response code, expected response body, test label ]
my @tests = (
   [ 'GET', '/assets', undef, 200, [], 'got no assets' ],
   [ 'POST', '/asset', undef, 400, 
      { error => 'Badly-formed request: path must be of form /assets/[id]/[notes]'}, 
      'error message is cleaned' 
   ],
   [ 'GET', '/notes', undef, 400, 
      { error => 'Badly-formed request: query param required for /notes request' }, 
      'another error' 
   ],
);

foreach my $test (@tests) {
   my ($method, $uri, $request_body, $exp_code, $exp_body, $label) = @$test;
   my $request_str = HTTPMessage::Request->new( 
      { method => $method, uri => $uri, message => $request_body} 
   )->as_string;

   my $response_str = $asset_api->process_request($request_str);
   my $response = HTTPMessage::Response->new_from_string($response_str);

   is($response->status_code, $exp_code, "code for $label"); 
   is_deeply($response->message, $exp_body, "message for $label"); 
}
