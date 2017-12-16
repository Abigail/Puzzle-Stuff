package Puzzle::Stuff::Polynome;

use 5.026;

use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';

use Hash::Util::FieldHash qw [fieldhash];

fieldhash my %coefficients;

sub new ($class) {
    bless do {\my $var} => $class;
}

sub init ($self, @coefficients) {
    pop @coefficients while @coefficients && !$coefficients [-1];
    $coefficients {$self} = [@coefficients];
    $self;
}

#
# Divide the polynome by another. Return the quotient and modulus.
#
sub divide ($self, $div) {
    my $divident = [@{$coefficients {$self}}];
    my $divisor  = [@{$coefficients {$div}}];
    my $quotient = [];

    while (@$divident >= @$divisor) {
        #
        # What's the power?
        #
        my $power = @$divident - @$divisor;

        #
        # How many times?
        #
        my $coefficient = $$divident [-1] / $$divisor [-1];

        $$quotient [$power] = $coefficient;

        #
        # Multiply and subtract.
        #
        foreach my $index (keys @$divisor) {
            $$divident [$index + $power] -= $coefficient * $$divisor [$index];
        }

        #
        # Pop the highest coefficient -- it ought to be 0,
        # but we may have round off errors.
        #
        pop @$divident;

        #
        # Pop any other leading 0s
        #
        while (@$divident && !$$divident [-1]) {
            pop @$divident;
        }
    }

    #
    # Whatever is left in $divident is the modulus
    #
    return ref ($self) -> new -> init (@$quotient),
           ref ($self) -> new -> init (@$divident);
}


#
# Format a polynome as a string
#
sub as_string ($self) {
    my @coefficients = @{$coefficients {$self}};
    my @out;
    foreach my $power (reverse keys @coefficients) {
        my $coefficient = $coefficients [$power] or next;
        $coefficient = $power == 0        ? $coefficient
                     : $coefficient ==  1 ? ""
                     : $coefficient == -1 ? "-"
                     :                      $coefficient;
        push @out => $power == 0 ?  $coefficient
                   : $power == 1 ? "$coefficient x"
                   :               "$coefficient x^$power"
    }
    @out    = (0) unless @out;
    my $str = join " + " => @out;

    #
    # Adding something negative can be subtraction
    #
    $str =~ s/\+\s*-\s*/- /g;

    #
    # Remove extra spaces
    #
    $str =~ s/\s{2,}/ /g;
    $str =~ s/^\s+//;

    $str;
}


#
# Return the coefficients of a polynome
#
sub coefficients ($self) {@{$coefficients {$self}}}




__END__
