
# Validate that, for the selected random values, dd_repro returns a
# a value that, when assigned to a new Math::FakeDD object, results in
# an identical copy of the original object that was given to dd_repro.
#
# Check also that the value returned by dd_repro consists of the fewest
# possible number of decimal digits.
# This is achieved by firstly checking that the equivalence is broken
# when the final digit of the mantissa is removed (truncated).
# We then check that raising (what is now) the final digit by 1 (rounding
# up) still renders the equivalence broken.
#
# Also run some basic sanity tests of int() and abs().

# DBL_MIN = 2.2250738585072014e-308 = 2 ** -1022

use strict;
use warnings;
use Math::FakeDD qw(:all);
use Test::More;

my $dbl_min = 2 ** -1022;

for(my $i = -300; $i <= 300; $i++) {
  for my $run (1..6) {
    my $input = rand();

    while(length($input) > 19) { chop $input }
    while($input =~ /0$/) { chop $input }

    my $str = "$input" . "e" . $i;
    $str = '-' . $str if $run & 1;

    my $orig = Math::FakeDD->new($str);

    my $repro   = dd_repro($orig);
    my $decimal = dd_dec  ($orig);
    my $hex     = dd_hex  ($orig);

    if($orig < 1 && $orig > -1) {
      cmp_ok(int($orig), '==', 0, "int() expected to return a value of 0");
    }
    else {
      cmp_ok(int($orig), '!=', 0, "int() expected to return a value other than 0");
    }

    my $dd_repro   = Math::FakeDD->new($repro);
    my $dd_decimal = Math::FakeDD->new($decimal);
    my $dd_hex     = Math::FakeDD->new($hex);

    cmp_ok($dd_repro, '==', $orig      , "string returned by dd_repro() assigns to original value");
    cmp_ok($dd_repro, '==', $dd_decimal, "exact decimal representation assigns correctly");
    cmp_ok($dd_hex  , '==', $dd_decimal, "dd_hex() and dd_dec() assign to same value");

    if($orig > 0) {
      cmp_ok($orig,      '==', abs($dd_repro * -1), "$str: abs() ok");
    }
    else {
      cmp_ok(abs($orig),      '==', abs($dd_repro * -1), "$str: abs() ok");
    }
    my $t = int(Math::FakeDD->new($repro));
    cmp_ok(int($orig), '==', $t                 , "$str: int() ok");

    my $check1 = Math::FakeDD->new($repro);
    cmp_ok($check1, '==', $orig, "$str: round trip achieved");

    my @chop  = split /e/i, $repro;
    chop($chop[0]);
    next if $chop[0] =~ /\.$/;

    if(!defined($chop[1])) {
      $repro = $chop[0];
    }
    else {
      $repro = $chop[0] . 'e' . $chop[1];
    }

    my $check2 = Math::FakeDD->new($repro);
    cmp_ok($check2, '!=', $orig, "$str: chop() alters value");
    cmp_ok(abs($check2), '<', abs($orig), "$str: test value < original");

    next if $chop[0] =~ /9$/;

    ++substr($chop[0], -1); # round up the last digit.

    if(!defined($chop[1])) {
      $repro = $chop[0];
    }
    else {
      $repro = $chop[0] . 'e' . $chop[1];
    }
    my $check3 = Math::FakeDD->new($repro);
    cmp_ok($check3, '!=', $orig, "$str: round-up alters value");
    cmp_ok(abs($check3), '>', abs($orig), "$str: test value > original");
  }
}

my $big =    (2 ** 140)   + (2 ** 100);
my $little = (2 ** -1000) + (2 ** -1019);

my $fudd1 = Math::FakeDD->new($big) + $little;
my $fudd2 = Math::FakeDD->new($big) - $little;

cmp_ok($fudd1, '>', $big, "big + little > big");
cmp_ok($fudd2, '<', $big, "big - little < big");

my $fudd3 = Math::FakeDD->new(dd_repro($fudd1));
my $fudd4 = Math::FakeDD->new(dd_repro($fudd2));

cmp_ok($fudd3, '==', $fudd1, "+: round trip ok");
cmp_ok($fudd4, '==', $fudd2, "-: round trip ok");

warn dd_repro($fudd1), "\n", dd_repro($fudd3), "\n";

done_testing();

