package Puzzle::Stuff::UnionFind;

use 5.026;

use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';

use Hash::Util 'fieldhash';

fieldhash my %universe;   # Maps elements to consecutive non-negative integers.
fieldhash my %parent;     # Array with parents; if the element does not
                          # have a parent, it's the root of the set.
fieldhash my %rank;       # Rank of a set.
fieldhash my %nr_of_sets; # Number of sets in the universe.

sub new ($class) {
    bless \do {my $var} => $class;
}

sub init ($self) {
    $universe   {$self} = {};
    $parent     {$self} = [];
    $rank       {$self} = [];
    $nr_of_sets {$self} = 0;
    $self;
}

#
# Add an element to the universe. It always starts as a set by itself.
#
sub add ($self, $element) {
    return $self if defined $universe {$self} {$element};

    #
    # We have a new element. Give it an index ($key)
    #
    my $key = @{$parent {$self} ||= []} + 1;

    #
    # Map the element to its key; set the parent to 0 (indicating it's the
    # root of the set); set the rank of its set to 0; increment the
    # number of sets.
    #
    $universe   {$self} {$element} = $key;
    $parent     {$self} [$key]     = 0;
    $rank       {$self} [$key]     = 0;
    $nr_of_sets {$self} ++;

    $self;
}

#
# Return the set the element is in. Do path compression if necessary
#
sub find ($self, $element) {
    my $universe = $universe {$self};
    my $parent   = $parent   {$self};

    #
    # Return undefined if we don't know about this element
    #
    my $key = $$universe {$element} // return undef;

    #
    # Walk the path to the parent. Remember the steps.
    #
    my @seen;
    while ($$parent [$key]) {
        push @seen => $key;
        $key = $$parent [$key];
    }

    #
    # Let all nodes visited point to the parent
    #
    if (@seen > 1) {
        pop @seen;
        $$parent [$_] = $key foreach @seen;
    }

    $key;
}

#
# Unite the sets of two elements; return the name of the united set.
# Nothing will happen (and undef returned) if not both elements are
# known in this universe.
#
sub union ($self, $element1, $element2) {
    my $set1 = $self -> find ($element1) // return;
    my $set2 = $self -> find ($element2) // return;

    my $parent = $parent {$self};
    my $rank   = $rank   {$self};

    #
    # If they're in the same set, we're done.
    #
    return $set1 if $set1 == $set2;

    my $return;

    #
    # Put the set with the smaller rank under the one with the larger;
    # if equal, put one under the other, and increase the rank of the set.
    #
    if    ($$rank [$set1] < $$rank [$set2]) {
        $$parent  [$set1] = $set2;
        $return =  $set2;
    }
    elsif ($$rank [$set2] < $$rank [$set1]) {
        $$parent  [$set2] = $set1;
        $return =  $set1;
    }
    else {
        $$parent  [$set1] = $set2;
        $$rank    [$set2] ++;
        $return =  $set2;
    }

    $nr_of_sets {$self} --;  # If two sets unite, the number of 
                             # sets decreases

    $return;
}


#
# Return the number of sets in this universe
#
sub nr_of_sets ($self) {
    $nr_of_sets {$self};
}


1;

__END__
