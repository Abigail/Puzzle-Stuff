package Puzzle::Stuff::KnotHash;

#
# For the 2017 edition of Advent of Code:
#     - day 10
#     - day 14
#
#
# Description of encoding using "knot hashes" from the day 10 problem
# of Advent of Code 2017. (http://adventofcode.com/2017/day/10)
#
#
# This hash function simulates tying a knot in a circle of string
# with 256 marks on it. Based on the input to be hashed, the function
# repeatedly selects a span of string, brings the ends together, and
# gives the span a half-twist to reverse the order of the marks within
# it. After doing this many times, the order of the marks is used to
# build the resulting hash.
#
#       4--5   pinch   4  5           4   1
#      /    \  5,0,1  / \/ \  twist  / \ / \
#     3      0  -->  3      0  -->  3   X   0
#      \    /         \ /\ /         \ / \ /
#       2--1           2  1           2   5
#
# To achieve this, begin with a list of numbers from 0 to 255, a
# current position which begins at 0 (the first element in the list),
# a skip size (which starts at 0), and a sequence of lengths (your
# puzzle input). Then, for each length:
#
#   - Reverse the order of that length of elements in the list,
#     starting with the element at the current position.
#   - Move the current position forward by that length plus the skip size.
#   - Increase the skip size by one.
#
# The list is circular; if the current position and the length try
# to reverse elements beyond the end of the list, the operation
# reverses using as many extra elements as it needs from the front
# of the list. If the current position moves past the end of the list,
# it wraps around to the front. Lengths larger than the size of the
# list are invalid.
#
# The logic you've constructed forms a single round of the Knot Hash
# algorithm; running the full thing requires many of these rounds.
# Some input and output processing is also required.
# 
# First, from now on, your input should be taken not as a list of
# numbers, but as a string of bytes instead. Unless otherwise specified,
# convert characters to bytes using their ASCII codes. This will allow
# you to handle arbitrary ASCII strings, and it also ensures that  
# your input lengths are never larger than 255. For example, if you
# are given 1,2,3, you should convert it to the ASCII codes for each
# character: 49,44,50,44,51.
#     
# Once you have determined the sequence of lengths to use, add the
# following lengths to the end of the sequence: 17, 31, 73, 47, 23.
# For example, if you are given 1,2,3, your final sequence of lengths
# should be 49,44,50,44,51,17,31,73,47,23 (the ASCII codes from the  
# input string combined with the standard length suffix values).
#     
# Second, instead of merely running one round like you did above, run
# a total of 64 rounds, using the same length sequence in each round.
# The current position and skip size should be preserved between
# rounds. For example, if the previous example was your first round,
# you would start your second round with the same length sequence (3,
# 4, 1, 5, 17, 31, 73, 47, 23, now assuming they came from ASCII codes
# and include the suffix), but start with the previous round's current
# position (4) and skip size (4).
#     
# Once the rounds are complete, you will be left with the numbers
# from 0 to 255 in some order, called the sparse hash. Your next task
# is to reduce these to a list of only 16 numbers called the dense
# hash. To do this, use numeric bitwise XOR to combine each consecutive
# block of 16 numbers in the sparse hash (there are 16 such blocks 
# in a list of 256 numbers). So, the first element in the dense hash
# is the first sixteen elements of the sparse hash XOR'd together,
# the second element in the dense hash is the second sixteen elements
# of the sparse hash XOR'd together, etc.
# 
# Finally, the standard way to represent a Knot Hash is as a single
# hexadecimal string; the final output is the dense hash in hexadecimal
# notation. Because each number in your dense hash will be between 0
# and 255 (inclusive), always represent each number as two hexadecimal
# digits (including a leading zero as necessary). So, if your first
# three numbers are 64, 7, 255, they correspond to the hexadecimal 
# numbers 40, 07, ff, and so the first six characters of the hash   
# would be 4007ff. Because every Knot Hash is sixteen such numbers,
# the hexadecimal representation is always 32 hexadecimal digits (0-f)
# long.



use 5.026;

use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';

my $DEFAULT_LIST_SIZE  = 256;
my $DEFAULT_ITERATIONS =  64;
my $DEFAULT_SUFFIX     = [17, 31, 73, 47, 23];


use Hash::Util 'fieldhash';

fieldhash my %list;
fieldhash my %position;
fieldhash my %skip;

################################################################################
#
# new ($class)
#
# Returns a new, unitialized object
#
################################################################################

sub new ($class) {
    bless do {\my $var} => $class;
}

################################################################################
#
# init ($self, %args)
#
# Initialize the object using the following optional arguments:
#    - size:    Size of list; we will have numbers 0 .. size - 1. Default 256
#
# Returns the object.
#
################################################################################

sub init ($self, %args) {
    my $size          = $args {size}     // $DEFAULT_LIST_SIZE;
    my $position      = $args {position} // 0;
    my $skip          = $args {skip}     // 0;

    $list {$self}     = [0 .. $size - 1];
    $position {$self} = $position;
    $skip     {$self} = $skip;

    $self;
}


################################################################################
#
# _move ($self, $length)
#
# Perform a single move of the given length, using the steps described above.
#
# Does not return anything useful.
#
################################################################################

sub _move ($self, $length) {
    #
    # Get the size of the list.
    #
    my $size = @{$list {$self}};

    #
    # Find the indices of the elements which need to be reversed.
    # This is simply starting from the current position, and then
    # the next $length - 1 element. (For a length of 0, this is
    # an empty list). We mod it with the length of the list to
    # handle the wrapping.
    #
    my @positions = map {$_ % $size} $position {$self} ..
                                    ($position {$self} + $length - 1);
    #
    # Reverse the elements by assigning a slice to a slice.
    #
    @{$list {$self}} [@positions] = @{$list {$self}} [reverse @positions];

    #
    # Increment the current position with the length of the move,
    # and the skip size; wrap the position, and increment the skip
    # size. (We could mod the skip size with the size of the list as
    # well, but that would only matter once skip reaches the size of
    # MAX_INT.)
    #
    $position {$self} += $length + $skip {$self} ++;
    $position {$self} %= $size;
}


################################################################################
#
# _dense_hash ($self)
#
# Calculate the dense hash, using the algorithm described above.
# Returns the dence hash as a 32 hex digit number.
#
################################################################################

sub _dense_hash ($self) {
    my $square = sqrt @{$list {$self}};
    my @xors;  # Xor-ed values of each $square set of numbers
    for (my $i = 0; $i < $square; $i ++) {
        my $xor = 0;
        for (my $j = 0; $j < $square; $j ++) {
            # Xor is communitative, so we can do them one-by-one
            $xor ^= ($list {$self} [$i * $square + $j] || 0);
        }
        push @xors => $xor;
    }
    
    # Concatenate all the values in hex digits.
    join "" => map {sprintf "%02x" => $_} @xors;
}


################################################################################
#
# _product ($self)
#
# Return the product of the first two numbers in the list.
#
################################################################################

sub _product ($self) {
    $list {$self} [0] * $list {$self} [1];
}


################################################################################
#
# encode ($self, $key, %args)
#
# Encode $key. $key can be a string, in which case we take the Unicode
# value of each character as the length of the substring to be reversed;
# else, $key is assumed to be an reference to an array containing lengths.
#
# Optional arguments:   
#    - no_suffix:   Do not apply a suffix to the key if true
#    - suffix:      Suffix to use instead of the default (17, 31, 73, 47, 23)
#    - iterations:  Number of iterations (default: 64)
#    - product:     If true, returns the product of the first two numbers
#                   (instead of the dense hash)
# 
# Returns the dense hash (32 hex digits), or, if the "product" option
# is given, the product of the first two numbers.
#
################################################################################

sub encode ($self, $key, %args) {
    my @moves = ref ($key) ? @$key
                           : map {ord} split // => $key;
    unless ($args {no_suffix}) {
        my @suffix = @$DEFAULT_SUFFIX;
        if ($args {suffix}) {
            @suffix = ref ($args {suffix})
                       ? @{$args {suffix}}
                       : map {ord} split // => $args {suffix};
        }
        push @moves => @suffix;
    }

    foreach (1 .. $args {iterations} // $DEFAULT_ITERATIONS) {
        $self -> _move ($_) for @moves;
    }

    return $args {product} ? $self -> _product
                           : $self -> _dense_hash;
}


1;


__END__
