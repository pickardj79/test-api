package HTTPMessage;

use strict;
use warnings FATAL => 'all';

use English qw(-no_match_vars);

# Base class for HTTP Messages (requests and responses)

# Fields

sub new {
   my ($class, $args) = @_;

   return bless {}, $class;
}

1;

