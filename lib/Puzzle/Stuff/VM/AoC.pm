package Puzzle::Stuff::VM::AoC;

use 5.026;

use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';

#
# A simple CPU/VM which is repeatedly used in Advent of Code problems
#

use Hash::Util::FieldHash qw [fieldhash];
use Scalar::Util          qw [looks_like_number];

fieldhash my %registers;
fieldhash my %pc;
fieldhash my %program;


sub new  ($class) {bless \do {my $var} => $class}
sub init ($self, %args) {
    if ($args {program}) {
        $program {$self} = $args {program};
    }
    $self;
}

sub value ($self, $register_or_value) {
    return $register_or_value if looks_like_number $register_or_value;
    return $registers {$self} {$register_or_value} // 0;
}


################################################################################
#
# Program counter
#
################################################################################

sub pc ($self) {
    $pc {$self}
}
sub set_pc ($self, $value) {
    $pc {$self} = $value;
    $self;
}
sub inc_pc ($self, $value = 1) {
    $pc {$self} += $value;
    $self;
}

sub current_instruction ($self) {
    @{$program {$self} [$self -> pc]};
}

################################################################################
#
# Set/get values of registers
#
################################################################################

sub set_register ($self, $register, $value) {
    $registers {$self} {$register} = $value;
    $self;
}

sub get_register ($self, $register) {
    $registers {$self} {$register} // 0;
}

sub reset_registers ($self) {
    $registers {$self} = { };
}


################################################################################
#
# Process an instruction
#
################################################################################

#
# set X Y
#
# Sets register X to the value of Y.
#
sub cmd_set ($self, $register, $value) {
    $self -> set_register ($register, $self -> value ($value));
    $self;
}

#########################
#
# Arithmetic
#
#########################

my sub arith ($self, $register, $op, $value) {
    state $dispatch = {
        '+'    =>  sub ($x, $y) {$x + $y},
        '-'    =>  sub ($x, $y) {$x - $y},
        '*'    =>  sub ($x, $y) {$x * $y},
        '/'    =>  sub ($x, $y) {int ($x / $y)},
        '%'    =>  sub ($x, $y) {$x % $y},
    };

    $self -> set_register (
        $register,
        $$dispatch {$op} -> ($self -> get_register ($register),
                             $self -> value ($value))
    );
    $self;
}

#
# add X Y
#
# Increments register X by the value of Y.
#
sub cmd_add ($self, $register, $value) {
    arith ($self, $register, "+", $value);
}

#
# sub X Y
#
# Decreases register X by the value of Y.
#
sub cmd_sub ($self, $register, $value) {
    arith ($self, $register, "-", $value);
}

#
# mul X Y
#
# Multiplies register X by the value of Y.
#
sub cmd_mul ($self, $register, $value) {
    arith ($self, $register, "*", $value);
}

#
# div X Y
#
# Divide register X by the value of Y. This will throw an error
# if Y is 0.
#
sub cmd_div ($self, $register, $value) {
    arith ($self, $register, "/", $value);
}

#
# mod X Y
#
# Set register X to the remainder of dividing its value by Y.
#
sub cmd_mod ($self, $register, $value) {
    arith ($self, $register, "%", $value);
}

#########################
#
# Jumping
#
#########################

#
# jnz X Y
#
# Jumps with an offset of the value of Y, but only if the value
# of X is not zero.
#
sub cmd_jnz ($self, $value, $offset) {
    $self -> inc_pc ($offset - 1) if $self -> value ($value);
}

#
# jgz X Y
#
# Jumps with an offset of the value of Y, but only if the value
# of X is greater than zero.
#
sub cmd_jgz ($self, $value, $offset) {
    $self -> inc_pc ($offset - 1) if $self -> value ($value) > 0;
}

################################################################################
#
# Run the program.
#
################################################################################

sub run ($self, %args) {
    $self -> set_pc (0);

    while ($self -> pc >= 0 && $self -> pc < @{$program {$self}}) {
        my ($instruction, @args) = $self -> current_instruction;
        my $method = "cmd_$instruction";
        die "Cannot perform instruction $instruction"
             unless $self -> can ($method);

        #
        # Increment the PC, then perform the instruction
        #
        $self -> inc_pc;
        $self -> $method (@args);
    }
}


1;

__END__
