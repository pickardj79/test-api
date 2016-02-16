#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use lib 'lib';

use Encode;
use HTTPMessage::Response;
use JSON::PP;
use Test::More tests => 4;

my $utf_bytes = encode_utf8("\x{2122}");
my $message = {
   'message-body' => 'a val',
   'line2' => $utf_bytes
};

my $response = HTTPMessage::Response->new( {
   status_code => 200,
   message => "text\x{2122}",
} );

is($response->as_string,
'HTTP/1.1 200 OK
Content-Length: 7
Content-Type: text/html
Connection: Closed

text' . $utf_bytes, 
   'built request as a string');


my $response2 = HTTPMessage::Response->new( {
   status_code => 400,
   message => { ahash => 'isjson' },
} );

is($response2->as_string,
'HTTP/1.1 400 Bad Request
Content-Length: 18
Content-Type: application/json
Connection: Closed

{"ahash":"isjson"}', 
   'built request2 as a string');

my $response3 = HTTPMessage::Response->new( {
   status_code => 302,
   message => [ 'anarray',  'also json' ],
} );

is($response3->as_string,
'HTTP/1.1 302 
Content-Length: 23
Content-Type: application/json
Connection: Closed

["anarray","also json"]',
   'built request3 as a string');


my $response4 = HTTPMessage::Response->new( {
   status_code => 200,
} );

is($response4->as_string,
'HTTP/1.1 200 OK
Content-Length: 0
Content-Type: text/html
Connection: Closed',
   'built request4 - no body');

