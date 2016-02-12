#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use English qw(-no_match_vars);
use IO::Socket::INET;

# flush after every write
$| = 1;

my ($socket,$client_socket);

# creating object interface of IO::Socket::INET modules which internally creates 
# socket, binds and connects to the TCP server running on the specific port.
$socket = IO::Socket::INET->new(
   PeerHost => '127.0.0.1',
   PeerPort => '17328',
   Proto => 'tcp',
) or die "ERROR in Socket Creation : $!\n";

print "TCP Connection Success.\n";

#my $recv_data;
#$socket->recv($recv_data,1024);
#print "Received from Server : $recv_data\n";

# write on the socket to server.
my $send_data = "DATA from Client";
#print $socket "$send_data\n";
# we can also send the data through IO::Socket::INET module,
$socket->send($send_data);

# read the socket data sent by server.
my $data = <$socket>;
# we can also read from socket through recv()  in IO::Socket::INET
# $socket->recv($data,1024);
print "Received from Server : " . ($data || '<undef>') . "\n";

$socket->close();
