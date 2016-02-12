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
# content - message body, can be scalar, hashref, or arrayref; 
#  automatically converts arrayref and hashref to json

my %FIELDS = ( 
   status_code => 1,
   content => 1,
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
   200 => 'OK',
   201 => 'Created',
   400 => 'Bad Request',
   404 => 'Not Found',
);

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

sub as_string {
   my ($self) = @_;

   my $content = $self->content;

   # convert hashref and arrayref content into json
   if ( UNIVERSAL::isa($content, 'ARRAY') || UNIVERSAL::isa($content, 'HASH') ) {
      $content = encode_json( $content );   
   }
   else {
      $content = encode_utf8( $content );
   }


   my $response = join("\n",
      join(" ", "HTTP/1.1", $self->status_code, $REASON_PHRASE{$self->status_code} || ''),
      "Content-Length: " . length($self->content || ''),
      "Content-Type: application/json",
      "Connection: Closed",
      "",
      $content,
   );

   return $response;

}

# accessorts
sub status_code {
   my ($self, $val) = @_;

   if (@_ == 2) {
      $self->{status_code} = $val;
   }

   return $self->{status_code};
}


sub content {
   my ($self, $val) = @_;

   if (@_ == 2) {
      $self->{content} = $val;
   }

   return $self->{content};
}

1;
