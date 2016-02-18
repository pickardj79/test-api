#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use lib 'lib';

use AssetServer;
use English qw(-no_match_vars);
use IO::Select;
use IO::Socket::INET;

# Runs a AssetServer listening for requests on 127.0.0.1:PORTNUMBER
# USAGE: perl Server.pl PORTNUMBER [QUEUESIZE]

# set autoflush on
$| = 1;

my $DEFAULT_LISTEN_QUEUE_SIZE = 5;
my $TIMEOUT_SECS = 5;
my $BLOCK_SIZE = 2048;

my ($port, $listen_queue) = validate_and_extract_inputs(@ARGV);

my $host = '127.0.0.1';

my $apiserver = AssetServer->new();

# Create socket listening on specified port
my $socket = IO::Socket::INET->new(
   LocalHost => $host,
   LocalPort => $port,
   Proto     => 'tcp',
   Listen    => $listen_queue,
) || die "ERROR in Socket Creation: $!\n";

print "Listening at $host:$port\n";
print "Ctrl-C terminates program\n";

# Wait for requests indefinately
while (1) {
   # accept a connection from a client
   my $cl_socket = $socket->accept();
   
   my $wait = IO::Select->new() ;
   $wait->add($cl_socket) ;
   
   my $cl_request = '';
   my $start = time;
   my $timeout = 0;

   # Read data from client
READ:
   while ( $wait->can_read(0) || !$cl_request ) {
      my $cur_read;
      $cl_socket->recv($cur_read, $BLOCK_SIZE);
      
      $cl_request .= $cur_read;

      last READ unless $cur_read;

      if ( time - $start > $TIMEOUT_SECS ) {
         my $timeout = 1;
         last READ;
      }
   }

   if (!$timeout) {
      # process request through api
      my $response = $apiserver->process_request($cl_request);

      # return response to client
      $cl_socket->send($response);
   }

   # close connection
   $cl_socket->close;
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

   my $listen_queue = $ARGV[1] || $DEFAULT_LISTEN_QUEUE_SIZE;

   if (!is_positive_int($listen_queue)) {
      print STDERR "Listen queue size must be a positive int\n";
      print_usage_and_exit();
   }

   return ($port, $listen_queue);
}

sub print_usage_and_exit {
   print STDERR "USAGE: perl $PROGRAM_NAME <port number> [listen queue size]\n";
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

END {
   $socket->close if $socket;
}

