package AssetServer;

use strict;
use warnings FATAL => 'all';

# TODO: finish building tests
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

sub process_request {
   my ( $self, $request ) = @_;

   my ($code, $body);
   eval {
      ($code, $body) = $self->_process_request($request);
   };
   if ($EVAL_ERROR) {
      return (HTTPMessage::Response::STATUS_BAD_REQUEST(), { $error => $EVAL_ERROR } ); 
   }

   return HTTPMessage::Response->new( {
      status_code => $code, content => $body 
   } )->as_string;
}

sub _process_request {
   my ($self, $request_str) = @_;

   die '$request is required as a scalar'
      unless $request_str && !ref $request_str;

   my $request_obj = HTTPMessage::Request->new_from_string( $request_str );

   my ($code, $body) 
      = $self->_api->process_request($request_obj->method, $request_obj->uri, $request_obj->message);

   return ($code, $body);
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

