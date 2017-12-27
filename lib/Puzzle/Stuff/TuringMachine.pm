package Puzzle::Stuff::TuringMachine;

use 5.026;

use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';

#
# Partial implementation of a Turing Machine
#

use Hash::Util::FieldHash qw [fieldhash];

my $RIGHT =  1;
my $LEFT  = -1;

fieldhash my %tape;
fieldhash my %state;
fieldhash my %program;
fieldhash my %start_state;
fieldhash my %cursor;

################################################################################
#
# new ($class)
#
# Creates an empty Turing Machine object.
#
################################################################################

sub new ($class) {bless do {\my $var} => $class}

################################################################################
#
# init ($self, %args)
#
# Initializes the Turing Machine. After processing its arguments, it will
# reset the machine.
#
# The following arguments should be given:
#   -  program:     The program to follow. It's hashref keyed on state and
#                   tape value; the values are triples: what to write on
#                   the tape; which way to move the cursor; the next state
#   -  start_state: The state the machine should start in.
#
################################################################################

sub init ($self, %args) {
    $program     {$self} = $args {program};
    $start_state {$self} = $args {start_state};
    $self -> reset;
}

################################################################################
#
# reset ($self)
#
# Resets the machine, so it's ready for a run. This means initializing
# it's tape to all 0s, resetting the cursor, and putting the machine
# in its start tape. Since reset() is called from init (), one only
# needs to call reset() if one wants to rerun the machine with the
# same program.
#
################################################################################

sub reset ($self) {
    $tape {$self}   = [0];
    $cursor {$self} =  0;
    $state  {$self} = $start_state {$self};
    $self;
}


################################################################################
#
# current ($self)
#
# Returns the value on the tape currently under the cursor.
#
################################################################################

sub current ($self) {
    $tape {$self} [$cursor {$self}] // 0;
}

################################################################################
#
# tape ($self)
#
# Returns the content of the tape.
#
################################################################################

sub tape ($self) {
    $tape {$self};
}


################################################################################
#
# run ($self, %args)
#
# Runs the machine. The following options will be accepted:
#    - run_for:   Run for the given amount of steps. If this option is
#                 not given (or if it's false), the machine will run
#                 forever, as no other termination condition has been
#                 implemented yet.
#
################################################################################

sub run ($self, %args) {
    my $count = 0;
    while (1) {
        my $info = $program {$self} {$state {$self}} {$self -> current} //
                    die "No info for state " . $state {$self} . " and " .
                        "current value " . $self -> current;
        my ($new_value, $direction, $next_state) = @$info;

        #
        # Write new value
        #
        $tape {$self} [$cursor {$self}] = $new_value;

        #
        # Move cursor. Since we assume we're acting on an infinite 
        # tape, we must deal with "running off" the tape. With the
        # current implementation this can happen if the cursor becomes
        # negative. In that case, we'll unshift some values, and 
        # adjust the cursor.
        #
        $cursor {$self} += $direction;
        if ($cursor {$self} < 0) {
            unshift @{$tape {$self}} => (0) x 10;
            $cursor {$self} += 10;
        }

        #
        # Next state
        #
        $state {$self} = $next_state;

        $count ++;
        last if $args {run_for} && $count >= $args {run_for};
    }

    $self;
}

1;

__END__
