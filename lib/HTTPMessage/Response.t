#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use lib 'lib';

use Data::Dumper;
use Encode;
use HTTPMessage::Response;
use JSON::PP;
use Test::More tests => 3;

my $utf_bytes = encode_utf8("\x{2122}");
my $content = {
   'message-body' => 'a val',
   'line2' => $utf_bytes
};

my $response = HTTPMessage::Response->new( {
   status_code => 200,
   content => "text\x{2122}",
} );

is($response->as_string,
'HTTP/1.1 200 OK
Content-Length: 5
Content-Type: application/json
Connection: Closed

text' . $utf_bytes, 
   'built request as a string');


my $response2 = HTTPMessage::Response->new( {
   status_code => 400,
   content => { ahash => 'isjson' },
} );

is($response2->as_string,
'HTTP/1.1 400 Bad Request
Content-Length: 20
Content-Type: application/json
Connection: Closed

{"ahash":"isjson"}', 
   'built request2 as a string');

my $response3 = HTTPMessage::Response->new( {
   status_code => 302,
   content => [ 'anarray',  'also json' ],
} );

is($response3->as_string,
'HTTP/1.1 302 
Content-Length: 21
Content-Type: application/json
Connection: Closed

["anarray","also json"]',
   'built request3 as a string');


