#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use lib 'lib';

use Data::Dumper;
use Encode;
use HTTPMessage::Request;
use JSON::PP;
use Test::More tests => 6;

my $utf_bytes = encode_utf8("\x{2122}");
my $content = {
   'message-body' => 'a val',
   'line2' => $utf_bytes
};

my $request_str = "POST /cgi-bin/process.cgi HTTP/1.1
User-Agent: Mozilla/4.0 (compatible; MSIE5.01; Windows NT)
Host: www.tutorialspoint.com
Connection: Keep-Alive

" . encode_json($content);

my $request = HTTPMessage::Request->new_from_string($request_str);

is($request->method, 'POST', 'parsed method');
is($request->uri, '/cgi-bin/process.cgi', 'parsed uri');
is_deeply($request->message, $content, 'parsed message');

my $request_str2 = "GET / HTTP/1.1
User-Agent: Mozilla/4.0 (compatible; MSIE5.01; Windows NT)
Host: www.tutorialspoint.com
Connection: Keep-Alive";

my $request2 = HTTPMessage::Request->new_from_string($request_str2);

is($request2->method, 'GET', 'parsed method 2');
is($request2->uri, '/', 'parsed uri 2');
is($request2->message, undef, 'parsed message 2');

