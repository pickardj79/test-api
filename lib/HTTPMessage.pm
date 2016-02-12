package HTTPMessage;

use strict;
use warnings FATAL => 'all';

# TODO: remove all Data::Dumper uses
use Data::Dumper;
use English qw(-no_match_vars);

# Base class for HTTP Messages (requests and responses)

# Fields

sub new {
   my ($class, $args) = @_;

   my $self = {};
   bless $self, $class;

   return $self;
}

1;

