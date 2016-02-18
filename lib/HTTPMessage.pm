package HTTPMessage;

use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use English qw(-no_match_vars);
use JSON::PP;

# Base class for HTTP Messages (requests and responses)

# Fields
# message: message body of HTTP Message

# parses first line of message, filling appropriate fields of $self
sub init_from_first_line { 
   my ($self, $first_line) = @_;
   die "Virtual sub, override in subclass";
}

sub fields { die "Virtual sub, override in subclass" }

sub new {
   my ($class, $args) = @_;

   die "\$args must be a hash ref"
      if $args && !UNIVERSAL::isa($args, 'HASH');
   
   my $self = bless {}, $class;
   
   foreach my $key ( keys %{$args || {}} ) {
      die "Unknown arg $key in \$args, got: " . Dumper $args
         unless grep { $key eq $_ } @{$self->fields}; 
   }
   
   foreach my $field ( @{$self->fields} ) {
      $self->$field( $args->{$field} );
   }

   return $self;
}

# instantiates an object from a HTTP string 
sub new_from_string {
   my ($class, $request_string) = @_;

   my $self = $class->new();

   my @request_lines = split("\n", $request_string);

   my $line_idx = 0;

   $self->init_from_first_line($request_lines[$line_idx]);
   
   # skip header lines - look for CRLF
   while ( ++$line_idx < scalar @request_lines ) { 
      last if $request_lines[$line_idx] =~ m/^\s*$/;
   }

   # the rest is the body
   if (++$line_idx <= $#request_lines) {
      my $encoded_message 
         = join("\n", @request_lines[$line_idx .. $#request_lines]);
      $self->message( decode_json($encoded_message) );
   }

   return $self;
}

# accessors
sub message {
   my ($self, $val) = @_;

   if (@_ == 2) {
      $self->{message} = $val;
   }

   return $self->{message};
}

1;

