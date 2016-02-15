package HTTPMessage::Response;

use base qw(HTTPMessage);

use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use Encode;
use English qw(-no_match_vars);
use JSON::PP;

# Class representing a HTTP Response

# Fields
# status_code - http status code
# message - message body, can be scalar, hashref, or arrayref; 
#  automatically converts arrayref and hashref to json

my %FIELDS = ( 
   status_code => 1,
   message => 1,
);

# Subs
# as_string - builds string representation of an http response from the object 

# example response
#HTTP/1.1 200 OK
#Date: Mon, 27 Jul 2009 12:28:53 GMT
#Server: Apache/2.2.14 (Win32)
#Last-Modified: Wed, 22 Jul 2009 19:15:56 GMT
#Content-Length: 88
#Content-Type: text/html
#Connection: Closed
#
# payload (match content-length/type)

my %REASON_PHRASE = (
   STATUS_OK()          => 'OK',
   STATUS_CREATED()     => 'Created',
   STATUS_BAD_REQUEST() => 'Bad Request',
   STATUS_NOT_FOUND()   => 'Not Found',
   STATUS_CONFLICT()    => 'Conflict',
   STATUS_INTERNAL_ERROR() => 'Internal Server Error',
);

sub STATUS_OK          { 200 }
sub STATUS_CREATED     { 201 }
sub STATUS_BAD_REQUEST { 400 }
sub STATUS_NOT_FOUND   { 404 }
sub STATUS_CONFLICT    { 409 }
sub STATUS_INTERNAL_ERROR { 500 }

sub new {
   my ($class, $args) = @_;

   die "\$args must be a hash ref"
      if $args && !UNIVERSAL::isa($args, 'HASH');
   foreach my $key ( keys %{$args || {}} ) {
      die "Unknown arg $key in \$args, got: " . Dumper $args
         unless $FIELDS{$key}; 
   }

   my $self = $class->SUPER::new($args);
   
   foreach my $field ( keys %FIELDS ) {
      $self->$field( $args->{$field} );
   }

   return $self;
}

sub init_from_first_line {
   my ($self, $first_line) = @_;

   my (undef, $code, $msg) = split(qr/\s+/, $first_line);
   $self->status_code($code);

   return;
}

sub as_string {
   my ($self) = @_;

   my $message = $self->message;
   my $contenttype;

   # convert hashref and arrayref content into json
   if ( UNIVERSAL::isa($message, 'ARRAY') || UNIVERSAL::isa($message, 'HASH') ) {
      $message = encode_json( $message );   
      $contenttype = 'application/json';
   }
   else {
      $message = encode_utf8( $message )
         if $message;
      $contenttype = 'text/html';
   }


   my $response = join("\n",
      join(" ", "HTTP/1.1", $self->status_code, $REASON_PHRASE{$self->status_code} || ''),
      "Content-Length: " . length($message || ''),
      "Content-Type: $contenttype",
      "Connection: Closed",
   );
   $response .= "\n\n$message"
      if defined $message;

   return $response;

}

# accessors
sub status_code {
   my ($self, $val) = @_;

   if (@_ == 2) {
      $self->{status_code} = $val;
   }

   return $self->{status_code};
}

1;
