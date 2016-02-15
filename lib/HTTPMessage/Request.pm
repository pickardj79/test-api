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
#Host: www.example.com
#Connection: Keep-Alive
#
#message-body


sub init_from_first_line {
   my ($self, $first_line) = @_;
   
   # first line has method and uri; assume this is HTTP/1.1
   my ($method, $uri) = split(qr/\s+/, $first_line);

   $self->method($method);
   $self->uri($uri);

   return;
}

sub as_string {
   my ($self) = @_;

   my $request_str = join("\n", $self->method . " " . $self->uri . " HTTP/1.1",
      "User-Agent: Mozilla/4.0",
      "Host: www.example.com",
      "Connection: Keep-Alive",
   );

   $request_str .= "\n\n" .  encode_json($self->message)
      if $self->message;

   return $request_str;
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

