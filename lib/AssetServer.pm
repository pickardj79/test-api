package AssetServer;

use strict;
use warnings FATAL => 'all';

use AssetAPI;
use English qw(-no_match_vars);
use HTTPMessage::Request;
use HTTPMessage::Response;

# Handler for HTTP requests into API

# Fields
# api 

sub new {
   my ($class) = @_;

   my $self = bless {}, $class;
   $self->_api( AssetAPI->new() );

   return $self;
}

# Takes an HTTP request as a string, parses from it the method, uri, and message body,
#  and uses the _api object to process
# Returns an HTTP response as a string
sub process_request {
   my ( $self, $request ) = @_;

   my ($code, $body);
   eval {
      ($code, $body) = $self->_process_request($request);
   };
   if ($EVAL_ERROR) {
      ($code, $body) =
         (HTTPMessage::Response::STATUS_INTERNAL_ERROR(), { error => $EVAL_ERROR } ); 
   }

   $self->_clean_error_msg($body);

   return HTTPMessage::Response->new( {
      status_code => $code, message => $body 
   } )->as_string;
}

sub _process_request {
   my ($self, $request_str) = @_;

   die '$request is required as a scalar'
      unless $request_str && !ref $request_str;

   my $request_obj;
   eval {
      $request_obj = HTTPMessage::Request->new_from_string( $request_str );
   };
   if ($EVAL_ERROR) {
      return (HTTPMessage::Response::STATUS_BAD_REQUEST, { error => $EVAL_ERROR } );
   }

   my ($code, $body) 
      = $self->_api->process_request($request_obj->method, $request_obj->uri, $request_obj->message);

   return ($code, $body);
}

# remove file and line number from error message
sub _clean_error_msg {
   my ($self, $body) = @_;

   return unless UNIVERSAL::isa($body, 'HASH');

   return unless defined $body->{error};

   chomp($body->{error});
   $body->{error} =~ s/ at [\w\/]+\.pm line \d+\.$//;
   return;
}

# accessors
sub _api {
   my ($self, $val) = @_;

   if (@_ == 2) {
      $self->{api} = $val;
   }

   return $self->{api};
}

1;

