package HTTPMessage::Request;

use base qw(HTTPMessage);

use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use English qw(-no_match_vars);
use JSON::PP;

# Class representing a HTTP Request 

# Fields
# method - http method
# uri - request uri
# message - message-body, json-encoded utf8

# Subs
# new_from_string - builds a object from a string representation of an http request

# example request:
#POST /cgi-bin/process.cgi HTTP/1.1
#User-Agent: Mozilla/4.0 (compatible; MSIE5.01; Windows NT)
#Host: www.tutorialspoint.com
#Connection: Keep-Alive
#
#message-body


# instantiates an object from a request_string
sub new_from_string {
   my ($class, $request_string) = @_;

   my $self = $class->new();

   my @request_lines = split("\n", $request_string);

   my $line_idx = 0;

   # first line has method and uri; assume this is HTTP/1.1
   my ($method, $uri) = split(qr/\s+/, $request_lines[$line_idx]);

   $self->method($method);
   $self->uri($uri);
   
   # skip header lines - look for CRLF
   while ( ++$line_idx < scalar @request_lines ) { 
      last if $request_lines[$line_idx] =~ m/^$/;
   }

   # the rest is the body
   if (++$line_idx <= $#request_lines) {
      my $encoded_message 
         = join("\n", @request_lines[$line_idx .. $#request_lines]);
      $self->message( decode_json($encoded_message) );
   }

   return $self;
}

# accessors
sub uri {
   my ($self, $val) = @_;

   if (@_ == 2) {
      $self->{uri} = $val;
   }

   return $self->{uri};
}

sub method {
   my ($self, $val) = @_;

   if (@_ == 2) {
      $self->{method} = $val;
   }

   return $self->{method};
}

sub message {
   my ($self, $val) = @_;

   if (@_ == 2) {
      $self->{message} = $val;
   }

   return $self->{message};
}

1;

