#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use CGI::Util qw(escape);
use Data::Dumper;
use English qw(-no_match_vars);
use JSON::PP;
use Time::HiRes qw(sleep time);

# Script to load test an active AssetServer running on 127.0.0.1:PORTNUMBER 
# Reports time required to run api requests

# USAGE: perl Client_LoadTest_curl.pl PORTNUMBER [NUMBER OF ITERATIONS] 

# NOTE: uses curl program to make requests, curl must be in $PATH 

# For every interation:
#  creates an asset, adds a note to that asset, requests a random asset,
#  requests the notes for that random asset, searches for that random asset
#  by name and then by uri.
# Every 4th iteration, deletes asset that was chosen randomly

my $DEFAULT_NUM_ITER = 100;
my ($port, $num_iter) = validate_and_extract_inputs(@ARGV);

my $BASE_URI = "http://127.0.0.1:$port";

my %assets;
my $ctr = 0;
my $total_sleep = 0;
my $start = time;

while (++$ctr < $num_iter) {
   # create an asset
   my $new_asset = { name => "asset${ctr}_$PID", uri => "uri${ctr}_$PID" };
   my $response_body = make_request('POST', '/assets', $new_asset);
   $new_asset->{id} = $response_body->{id};
   $assets{ $new_asset->{id} } = $new_asset;

   # create a note for the just created asset and then for a random asset
   my $new_note = { assetid => $new_asset->{id}, note => "this is a note" };
   make_request('POST', "/assets/$new_asset->{id}/notes", $new_note );
   
   # get a random asset by id, and search by each name and uri; then get its notes
   my $assetid = (keys %assets)[0];
   make_request('GET', "/assets/$assetid");
   make_request('GET', "/assets/$assetid/notes");
   make_request('GET', "/assets?asset_name=" . escape($assets{$assetid}->{name} ));
   make_request('GET', "/assets?asset_uri="  . escape($assets{$assetid}->{uri} ));

   # delete every 4th asset
   if ($ctr % 4 == 0) {
      make_request('DELETE', "/assets/$assetid");
      delete $assets{$assetid};
   }
}

print "Made " . ($ctr * 6.25) . " requests in " . (time - $start - $total_sleep) . " seconds\n";

sub make_request {
   my ($method, $uri, $content) = @_;

   my $cmd = "curl $BASE_URI$uri -X$method";
   $cmd .= " -d'" . encode_json($content) . "'"
      if $content;
   
   #print "Running $cmd\n";
   my $response = `$cmd 2>/dev/null`;

   my $decoded_response = decode_json($response)
      if $response;
   return $decoded_response;
}

################
##### Helper subs

sub validate_and_extract_inputs {
   my (@inputs) = @_;
   
   my $port = $ARGV[0];

   if (!$port) {
      print STDERR "Missing port number\n";
      print_usage_and_exit();
   }

   if (!is_positive_int($port)) {
      print STDERR "Port number must be a positive int\n";
      print_usage_and_exit();
   }

   my $num_iter = $ARGV[1] || $DEFAULT_NUM_ITER;

   if (!is_positive_int($num_iter)) {
      print STDERR "Listen queue size must be a positive int\n";
      print_usage_and_exit();
   }

   return ($port, $num_iter);
}

sub print_usage_and_exit {
   print STDERR "USAGE: perl $PROGRAM_NAME <port number> [number of iterations]\n";
   exit(1);
}

sub is_positive_int {
   my ($x) = @_;

   return unless $x;
   return unless $x =~ m/^\d+$/;
   return unless $x = int($x);
   return unless $x > 0;
   return 1;
}
