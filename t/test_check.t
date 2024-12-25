
# Check that the values that dd_repro_test uses internally are as expected.
# It's intended that additional tests will included over time.
# DBL_MIN = 2.2250738585072014e-308 = 2 ** -1022

use strict;
use warnings;
use Math::FakeDD qw(:all);
use Test::More;

for my $val(119984 .. 120006) {
  my $s = "$val" . '.0';
  my $dd = Math::FakeDD->new($s);
  cmp_ok($dd, '==', $s + 0, "$s: equivalence ok");
  my $repro = dd_repro($dd);
  cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$s: dd_repro_test ok");
  cmp_ok($s, 'eq', $Math::FakeDD::examine{repro}, "$s: \$Math::FakeDD::examine{repro} ok");
  my $chopped = "$val";
  my $exponent = 0;
  while($chopped =~ /0$/) {
    chop $chopped;
    $exponent++;
  }
  chop $chopped;
  my $inc = ($chopped + 1) . 0;
  $chopped .= 0;
  $chopped .= "e$exponent" if $exponent;
  cmp_ok($chopped, 'eq', $Math::FakeDD::examine{chop}, "$s: \$Math::FakeDD::examine{chop} ok");
  cmp_ok($inc, 'eq', (split(/e/i, $Math::FakeDD::examine{inc}))[0], "$s: \$Math::FakeDD::examine{inc} ok");
}

#print "INC: ", $Math::FakeDD::examine{inc}, "\n";
#print "CHOP: ", $Math::FakeDD::examine{chop}, "\n";

done_testing();


