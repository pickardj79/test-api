package AssetAPI;

use strict;
use warnings FATAL => 'all';

#TODO: remove all data::dumpers, DB::single too
use Data::Dumper;

use CGI::Util qw(unescape);
use DataObject::Asset;
use DataObject::AssetNote;
use Datastore::Memory;
use English qw(-no_match_vars);
use HTTPMessage::Response;
use List::Util qw(first);

# Handler for HTTP requests into API

my $BAD_REQUEST_MSG = 'Badly-formed request';
my $MISSING_ASSET_MSG = 'Could not find asset';
my @ALLOWED_QUERY_PARAMS = qw(asset_uri asset_name);

# Fields
# _datastore_assets = storage for Assets
# _datastore_notes = storage for AssetNotes

sub new {
   my ($class) = @_;

   my $self = bless {}, $class;
   $self->_datastore_assets( Datastore::Memory->new() );
   $self->_datastore_notes( Datastore::Memory->new() );

   $self->_datastore_assets->add_index('name');
   $self->_datastore_assets->add_index('uri');

   $self->_datastore_notes->add_index('assetid');
   
   return $self;
}

# path is of the form: /assets/[id]/[notes]?[optional query]
# query is of the form: ?assetname=%-encoded name
#                   or: ?asseturi=%-encododed uri
sub process_request {
   my ($self, $method, $uri, $request_body) = @_;

   my ($code, $message);

   eval {
      die "$BAD_REQUEST_MSG: unsupported HTTP method"
         if !first { $method eq $_ } qw(GET POST DELETE);
      
      my ($assetid, $is_notes_request) = $self->_analyze_uri($uri);
      
      if ($method eq 'GET') {
         ($code, $message) 
            = $self->_process_get($assetid, $is_notes_request, $request_body);
      }
      elsif ($method eq 'POST') {
         ($code, $message) 
            = $self->_process_post($assetid, $is_notes_request, $request_body);
      }
      elsif ($method eq 'DELETE') {
         ($code, $message) 
            = $self->_process_delete($assetid, $is_notes_request, $request_body);
      }
      else {
      }
   };
   
   if (my $err = $EVAL_ERROR) {
      if ($err =~ qr/^$BAD_REQUEST_MSG/) {
         return (HTTPMessage::Response::STATUS_BAD_REQUEST, { error => $err } );
      }
      elsif ($err =~ qr/^$MISSING_ASSET_MSG/) {
         return (HTTPMessage::Response::STATUS_NOT_FOUND, { error => $err } );
      }
      
      die $err;
   }

   return ( $code, $message );
}

# analyzes uri to validate correct structure and determine assetid (if present)
#  and if notes were requested
# returns assetid (could be undef) and if notes were requested (boolean)
# throws errors for incorrectly formatted request or unknown assetid
sub _analyze_uri {
   my ($self, $uri) = @_;

   my ($paths, $params) = $self->_parse_uri($uri);

   die "$BAD_REQUEST_MSG: path must be of form /assets/[id]/[notes]"
      if @$paths == 0 || @$paths > 3 
         || ( $paths->[0] ne 'assets' && $paths->[0] ne 'notes' )
         || (@$paths == 3 && $paths->[2] ne 'notes');
   
   die "$BAD_REQUEST_MSG: cannot specify an asset id and an asset query param"
      if @$paths > 1 && keys %$params;

   die "$BAD_REQUEST_MSG: query param required for notes request"
      if $paths->[0] eq 'notes' && !keys %$params;
   
   die "$BAD_REQUEST_MSG: only one query param allowed"
      if keys %$params > 1;
   
   foreach my $key ( keys %$params ){
      die "$BAD_REQUEST_MSG: allowed query params are @ALLOWED_QUERY_PARAMS"
         if !first { $_ eq $key } @ALLOWED_QUERY_PARAMS;
   }

   my $assetid;
   if (@$paths >= 2) {
      $assetid = $paths->[1];
      
      # confirm the asset exists
      die "$MISSING_ASSET_MSG with assetid '$assetid'"
         if !$self->_datastore_assets->retrieve( $assetid );
   }
   else {
      while ( my ($param, $value) = each %$params ) {
         my $unescaped_val = unescape($value);
         $assetid = $self->_find_assetid_by_name($unescaped_val)
            if $param eq 'asset_name';
         $assetid = $self->_find_assetid_by_uri($unescaped_val)
            if $param eq 'asset_uri';

         die "$MISSING_ASSET_MSG with $param = '$value'" if !$assetid;
      }
   }

   my $is_notes_request = @$paths == 3 || $paths->[0] eq 'notes';

   return ($assetid, $is_notes_request);
}

sub _parse_uri {
   my ($self, $uri) = @_;

   die "unrecognized uri $uri"
      unless $uri =~ m{^/};

   my ($path, $query) = split(qr/\?/, $uri);

   my @paths = split(qr{/}, $path);

   my %query_params;
   foreach my $keyval ( split(qr/&/, $query || '') ) {
      my ($key, $val) = split(qr/=/, $keyval);
      $query_params{$key} = $val;
   }

   # 0th element of @paths is '', the part before the first /
   return ( [ @paths[1..$#paths] ], \%query_params);
}

sub _find_assetid_by_name {
   my ($self, $name) = @_;
   my $ids = $self->_datastore_assets->get_ids_by_index($name, 'name');
   
   die "found multiple ids for name $name"
      if @$ids > 1;

   return unless @$ids;
   return $ids->[0];
}

sub _find_assetid_by_uri {
   my ($self, $uri) = @_;
   my $ids = $self->_datastore_assets->get_ids_by_index($uri, 'uri');

   die "found multiple ids for uri $uri"
      if @$ids > 1;

   return unless @$ids;
   return $ids->[0];
}

sub _process_get {
   my ($self, $assetid, $is_notes_request, $request_body) = @_;

   die "$BAD_REQUEST_MSG: Cannot GET notes without an assetid"
      if $is_notes_request && ! defined $assetid;

   die "$BAD_REQUEST_MSG: Cannot use GET with a message body"
      if $request_body;

   my $results = [];
   if ( ! defined $assetid ) {
      # list all assets
      my $results_hash = $self->_datastore_assets->retrieve_all;
      while (my ($id, $asset) = each %$results_hash) {
         my $hashed_asset = $asset->hashify;
         $hashed_asset->{id} = $id;
         push @$results, $hashed_asset;
      }
   }
   elsif( $is_notes_request ) {
      # get all notes for an asset
      my $ids 
         = $self->_datastore_notes->get_ids_by_index( $assetid, 'assetid' );
      $results = [ map { $self->_datastore_notes->retrieve($_)->hashify } @$ids ];
   }
   else {
      # get a specific asset
      my $asset = $self->_datastore_assets->retrieve( $assetid );
      my $hashed_asset = $asset->hashify;
      $hashed_asset->{id} = $assetid;
      $results = [ $hashed_asset ];
   }

   return (HTTPMessage::Response::STATUS_OK, $results);
}

sub _process_post {
   my ($self, $assetid, $is_notes_request, $request_body) = @_;

   die "$BAD_REQUEST_MSG: missing message body"
      unless $request_body;

   die "$BAD_REQUEST_MSG: badly-formed message body"
      unless UNIVERSAL::isa($request_body, 'HASH');

   my $id;
   if ($is_notes_request) {
      die "$BAD_REQUEST_MSG: cannot create notes without an assetid"
         unless defined $assetid;

      my $note;
      eval {
         $note = DataObject::AssetNote->new( 
            { assetid => $assetid, %$request_body }
         );
      };
      die "$BAD_REQUEST_MSG: badly-formed create note request, $EVAL_ERROR"
         if $EVAL_ERROR;

      $id = $self->_datastore_notes->insert( $note );
   }
   else {
      die "$BAD_REQUEST_MSG: cannot specify an assetid when creating an asset"
         if defined $assetid;

      my $asset;
      eval {
         $asset = DataObject::Asset->new( $request_body );
      };
      die "$BAD_REQUEST_MSG: badly-formed create asset request, $EVAL_ERROR"
         if $EVAL_ERROR;
      
      my $existing_asset_id = $self->_find_assetid_by_name( $asset->name )
         || $self->_find_assetid_by_uri( $asset->uri );

      return ( HTTPMessage::Response::STATUS_CONFLICT, { 
         error => "asset with name '" . $asset->name . "' already exists"
      } )
         if $self->_find_assetid_by_name( $asset->name );

      return ( HTTPMessage::Response::STATUS_CONFLICT, { 
         error => "asset with uri '" . $asset->uri . "' already exists"
      } )
         if $self->_find_assetid_by_uri( $asset->uri );

      $id = $self->_datastore_assets->insert( $asset );
   }

   return (HTTPMessage::Response::STATUS_CREATED, { id => $id } );
}

sub _process_delete {
   my ($self, $assetid, $is_notes_request, $request_body) = @_;

   die "$BAD_REQUEST_MSG: cannot delete notes"
      if $is_notes_request;

   die "$BAD_REQUEST_MSG: assetid required for delete"
      unless $assetid;

   die "$BAD_REQUEST_MSG: Cannot use DELETE with a message body"
      if $request_body;

   $self->_datastore_assets->delete($assetid);

   return (HTTPMessage::Response::STATUS_OK, undef);
}

# accessors
sub _datastore_assets {
   my ($self, $val) = @_;

   if (@_ == 2) {
      $self->{_datastore_assets} = $val;
   }

   return $self->{_datastore_assets};
}


sub _datastore_notes {
   my ($self, $val) = @_;

   if (@_ == 2) {
      $self->{_datastore_notes} = $val;
   }

   return $self->{_datastore_notes};
}
