
package Math::FakeDD::DDTest;
use strict;
use warnings;
use Math::FakeDD qw(:all);

use Test::More;

require Exporter;
*import = \&Exporter::import;

$Math::FakeDD::DDTest::VERSION = '0.04';

@Math::FakeDD::DDTest::EXPORT = qw( chop_inc_test );
%Math::FakeDD::DDTest::EXPORT_TAGS = (all =>[@Math::FakeDD::DDTest::EXPORT]);

sub chop_inc_test {
  # 1st arg is a Math::FakeDD object.
  # Optional 2nd arg will produce some 'debug' output
  # if it is a case-insensitive match of 'debug'.

  # If the three tests in this sub pass, then we have shown:
  # 1) that $repro assigns to $op
  #   &&
  # 2) that $repro will not assign to $op if we remove any
  #    of its mantissa digits.

  my $op = shift;
  $op = abs($op); # TODO - remove this stipulation
  my $repro = dd_repro($op);

  # Skip testing of Infs, Nan, and Zero.
  return 1
    if(dd_is_nan($op) || dd_is_inf($op) || $op == 0);

  cmp_ok(Math::FakeDD->new($repro), '==', $op, sprintx($op) . " round trip ok");

  my $debug = defined($_[0]) ? $_[0] : 0;
  $debug = $debug =~/debug/i ? 1     : 0;

  print "OP:\n$op\n"       if $debug;
  print "REPRO:\n$repro\n" if $debug;
  my @r = split /e/i, $repro;
  print "SPLIT:\n$r[0]\n" if $debug;
  if($debug) {
    if(defined($r[1])) { print "$r[1]\n" }
    else { print "no exponent\n" }
  }

  # We remove from $repro any trailing mantissa zeroes, and then
  # replace the least significant digit with zero.
  # IOW, we effectively chop off the least siginificant digit, thereby
  # rounding it down to the next lowest decimal precision.)
  # This altered string should assign to a DoubleDouble value that is
  # less than the given $op.

  chop($r[0]) while $r[0] =~ /0$/;
  $r[0] =~ s/\.$//;
  return 2 if $r[0] =~ /0$/;     # TODO
  return 3 if length($r[0]) < 3; # TODO
  substr($r[0], -1, 1, '0');

  my $chopped = defined($r[1]) ? $r[0] . 'e' . $r[1]
                               : $r[0];

  print "CHOPPED:\n$chopped\n\n" if $debug;

  cmp_ok(Math::FakeDD->new($chopped), '<', $op, sprintx($op) . " chop test ok");

  # Now we derive a value that is $repro rounded up to the next lowest
  # decimal representation.
  # This value should assign to a  DoubleDouble value that is greater
  # than the given $op.

  if($r[0] =~ /\./) {
    # We must remove the '.', do the string increment,
    # and then reinsert the '.' in the appropriate place.
    my @mantissa = split /\./, $r[0];
    my $point_pos = -(length($mantissa[1]));
    my $t = $mantissa[0] . $mantissa[1];
    $t++ for 1..10;
    substr($t, $point_pos, 0, '.');
    $r[0] = $t;
  }
  else {
    $r[0]++ for 1..10;
  }
  my $incremented = defined($r[1]) ? $r[0] . 'e' . $r[1]
                                   : $r[0];

  print "INCREMENTED:\n$incremented\n" if $debug;;
  cmp_ok(Math::FakeDD->new($incremented), '>', $op, sprintx($op) . " inc test ok");
}

1;
