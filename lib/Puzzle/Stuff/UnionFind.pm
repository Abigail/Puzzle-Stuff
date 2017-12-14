package Puzzle::Stuff::UnionFind;

use 5.026;

use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';

use Hash::Util 'fieldhash';

fieldhash my %universe;   # Maps elements to consecutive non-negative integers
fieldhash my %parent;     # Array with parents; each element has exactly
                          # one parent. If the parent is the same as the
                          # element, it's the top of the set.
fieldhash my %size;       # Number of elements in a set
fieldhash my %nr_of_sets; # Number of sets in universe

sub new ($class) {
    bless \do {my $var} => $class;
}

sub init ($self) {
    $universe   {$self} = {};
    $parent     {$self} = [];
    $size       {$self} = [];
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
    my $key = @{$parent {$self} ||= []};

    #
    # Map the element to its key; set itself as the parent (it's the root
    # of its set); set the size of its set to 1; increment the number of sets
    #
    $universe   {$self} {$element} = $key;
    $parent     {$self} [$key]     = $key;
    $size       {$self} [$key]     = 1;
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
    while ($key != $$parent [$key]) {
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
    my $size   = $size   {$self};

    #
    # If they're in the same set, we're done.
    #
    return $set1 if $set1 == $set2;

    #
    # Put the smaller set right under the root of the larger
    #
    ($set1, $set2) = ($set2, $set1) if $$size [$set2] < $$size [$set1];

    $$parent [$set1]  = $set2;
    $$size   [$set2] += $$size [$set1];
    $$size   [$set1]  = undef;

    $nr_of_sets {$self} --;  # If two sets unite, the number of 
                             # sets decreases

    $set2;
}


#
# Return the number of sets in this universe
#
sub nr_of_sets ($self) {
    $nr_of_sets {$self};
}


1;

__END__
