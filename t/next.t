use strict;
use warnings;
use Math::FakeDD qw(:all);
use Config;

use constant CHECK1 => $Config{ivsize} >= 8 ? 1 : 0;

# If perl's nvtype is the extended precision (80 bit) long double, then
# CHECK2 is set to 0. Otherwise it's set to 1. The 80 bit long double is
# different from the other 2 nvtypes in that its "%a" formatting does not
# begin with "0x1."
# I might accommodate in the tests at some point in the future.
use constant CHECK2 => Math::FakeDD::NV_IS_DOUBLE | Math::FakeDD::NV_IS_QUAD;

use Test::More;

my $expected_exponent;
my $explanation = '';
unless(CHECK2) {
  $explanation = " (because NVTYPE is 80-bit long double)";
}
unless(CHECK1) {
  $explanation = " (because IVSIZE is 4)";
}

my $nan  = dd_nan();   # nan
my $pinf = dd_inf();   # +ve inf
my $ninf = dd_inf(-1); # -ve inf
my $pzero = Math::FakeDD->new(0);
my $nzero = $pzero * -1;
my $dd_denorm_min = Math::FakeDD->new(Math::FakeDD::DBL_DENORM_MIN);
my $sanity_checks = 0;

cmp_ok(ulp_exponent($pinf),  '==', -1074, "ulp_exponent(inf)  returns -1074");
cmp_ok(ulp_exponent($ninf),  '==', -1074, "ulp_exponent(-inf) returns -1074");
cmp_ok(ulp_exponent($nan),   '==', -1074, "ulp_exponent(nan)  returns -1074");
cmp_ok(ulp_exponent($pzero), '==', -1074, "ulp_exponent(0)    returns -1074");
cmp_ok(ulp_exponent($nzero), '==', -1074, "ulp_exponent(-0)   returns -1074");

# Run some checks on is_subnormal()
cmp_ok(is_subnormal($pinf->{msd}),  '==', 0, "is_subnormal(inf)  returns 0");
cmp_ok(is_subnormal($ninf->{msd}),  '==', 0, "is_subnormal(-inf) returns 0");
cmp_ok(is_subnormal($nan->{msd}),   '==', 0, "is_subnormal(nan)  returns 0");
cmp_ok(is_subnormal($pzero->{msd}), '==', 1, "is_subnormal(0)    returns 1");
cmp_ok(is_subnormal($nzero->{msd}), '==', 1, "is_subnormal(-0)   returns 1");
cmp_ok(is_subnormal(2**-1022), '==', 0, "is_subnormal(2**-1022) returns 0");
cmp_ok(is_subnormal(2**-1023), '==', 1, "is_subnormal(2**-1023) returns 1");
cmp_ok(is_subnormal(2**-1022 + 2**-1023), '==', 0, "is_subnormal(2**-1022 + 2**-1023) returns 0");
cmp_ok(is_subnormal(2**-1022 - 2**-1074), '==', 1, "is_subnormal(2**-1022 - 2**-1074) returns 1");

my $nu = dd_nextup($nan);
cmp_ok(dd_is_nan($nu), '!=', 0, "nextup from NaN is NaN");

my $nd= dd_nextdown($nan);
cmp_ok(dd_is_nan($nd), '!=', 0, "nextdown from NaN is NaN");

$nu = dd_nextup($pinf);
cmp_ok($nu, '>', 0, "nextup from +Inf is greater than 0");
cmp_ok(dd_is_inf($nu), '!=', 0, "nextup from +Inf is Inf");

$nd = dd_nextdown($pinf);
cmp_ok($nd, '==', $Math::FakeDD::DD_MAX, "nextdown from +Inf is " . $Math::FakeDD::DD_MAX);

$nu = dd_nextup($ninf);
cmp_ok($nu, '==', -$Math::FakeDD::DD_MAX, "nextup from -Inf is " . -$Math::FakeDD::DD_MAX);

$nd = dd_nextdown($ninf);
cmp_ok($nd, '<', 0, "nextdown from -Inf is less than 0");
cmp_ok(dd_is_inf($nd), '!=', 0, "nextdown from -Inf is Inf");

$nu = dd_nextup($pzero);
cmp_ok($nu, '==', Math::FakeDD::DBL_DENORM_MIN, "nextup from +0 is $dd_denorm_min");

$nd = dd_nextdown($pzero);
cmp_ok($nd, '==', -Math::FakeDD::DBL_DENORM_MIN, "nextdown from +0 is " . -$dd_denorm_min);

$nu = dd_nextup($nzero);
cmp_ok($nu, '==', Math::FakeDD::DBL_DENORM_MIN, "nextup from -0 is $dd_denorm_min");

$nd = dd_nextdown($nzero);
cmp_ok($nd, '==', -Math::FakeDD::DBL_DENORM_MIN, "nextdown from +0 is " . -$dd_denorm_min);

my $dd_norm_min = Math::FakeDD->new(2 ** -1022);
my $dd_subnorm_max = dd_nextdown($dd_norm_min);
cmp_ok(is_subnormal($dd_subnorm_max->{msd}), '==', 1, "nextdown from 2**-1022 is subnormal");
cmp_ok(dd_nextup($dd_subnorm_max), '==', $dd_norm_min, "nextup from max subnormal is normal");

###############################################################################################
my $dd = Math::FakeDD->new(2 ** -1022) + (2 ** -1074);
# [2.225073858507202e-308 0.0]

$nu = dd_nextup($dd);
# [2.2250738585072024e-308 0.0]

cmp_ok($nu, '==', Math::FakeDD->new(2 **-1022) + (2 ** -1073),
                 "dd_nextup(2 ** -1022) + (2 ** -1074)) == (2 ** -1022) + (2 ** -1073)");
cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$nu - $dd ok");

$nd = dd_nextdown($dd);
# [2.2250738585072014e-308 0.0]

cmp_ok($nd, '==', Math::FakeDD->new(2 **-1022),
                 "dd_nextdown(2 ** -1022) + (2 ** -1074)) == (2 ** -1022)");
cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$dd - $nd ok");

if(should_not_fail($dd)) {
  cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip");
  cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip");
}
else {
  warn "Skipped up-down & down-up round trip tests: " .sprintx($dd);
}

$dd = Math::FakeDD->new(-(2 ** -1022)) - (2 ** -1074);
# [-2.225073858507202e-308 0.0]

$nu = dd_nextup($dd);
# [-2.2250738585072014e-308 0.0]

cmp_ok($nu, '==', Math::FakeDD->new(-(2 **-1022)),
                 "dd_nextup(-(2 ** -1022)) - (2 ** -1074)) == -(2 ** -1022)");
cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$nu - $dd ok");

$nd = dd_nextdown($dd);
# [-2.2250738585072024e-308 0.0]

cmp_ok($nd, '==', Math::FakeDD->new(-(2 **-1022)) - (2 ** -1073),
                 "dd_nextdown(-(2 ** -1022)) - (2 ** -1074)) == -(2 ** -1022) - (2 ** -1073)");
cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$dd - $nd ok");

if(should_not_fail($dd)) {
  cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip");
  cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip");
}
else {
  warn "Skipped up-down & down-up round trip tests: " .sprintx($dd);
}
###############################################################################################
###############################################################################################
$dd = Math::FakeDD->new(2 ** -1000) + (2 ** -1052);
# [9.33263618503219e-302 0.0]

$nu = dd_nextup($dd);
# [9.33263618503219e-302 5e-324]

cmp_ok($nu, '==', Math::FakeDD->new(2 **-1000) + (2 ** -1052) + Math::FakeDD::DBL_DENORM_MIN,
                 "dd_nextup(2 ** -1000) + (2 ** -1052)) == (2 ** -1000) + (2 ** -1052) + (2 ** -1074)");
cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$nu - $dd ok");

$nd = dd_nextdown($dd);
# [9.33263618503219e-302 -5e-324]

cmp_ok($nd, '==', Math::FakeDD->new(2 **-1000) + (2 ** -1052) - Math::FakeDD::DBL_DENORM_MIN,
                 "dd_nextdown(2 ** -1000) + (2 ** -1052)) == (2 ** -1000) + (2 ** -1052) -(2 ** -1074)");
cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$dd - $nd ok");

if(should_not_fail($dd)) {
  cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip");
  cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip");
}
else {
  warn "Skipped up-down & down-up round trip tests: " .sprintx($dd);
}

$dd = Math::FakeDD->new(-(2 ** -1000)) - (2 ** -1052);
# [-9.33263618503219e-302 0.0]

$nu = dd_nextup($dd);
# [-9.33263618503219e-302 5e-324]

cmp_ok($nu, '==', Math::FakeDD->new(-(2 **-1000)) - (2 ** -1052) + Math::FakeDD::DBL_DENORM_MIN,
                 "dd_nextup(-(2 ** -1000)) - (2 ** -1052)) == -(2 ** -1000) -(2 ** -1052) + (2 ** -1074)");
cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$nu - $dd ok");

$nd = dd_nextdown($dd);
# [-9.33263618503219e-302 -5e-324]

cmp_ok($nd, '==', Math::FakeDD->new(-(2 **-1000)) - (2 ** -1052)  - Math::FakeDD::DBL_DENORM_MIN,
                 "dd_nextdown(-(2 ** -1000)) - (2 ** -1052)) == -(2 ** -1000) - (2 ** -1052) -(2 ** -1074)");
cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$dd - $nd ok");

if(should_not_fail($dd)) {
  cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip");
  cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip");
}
else {
  warn "Skipped up-down & down-up round trip tests: " .sprintx($dd);
}
###############################################################################################

for(1 .. 100) {
  my $p1 = int(rand(1024));
  $p1 *= -1 if $_ % 2; # check for equal numbers of -ve and +ve powers
  my $p2 = $p1 - int(rand(52));

  my $first  = 2 ** $p1;
  my $second = 2 ** $p2;

  $dd = Math::FakeDD->new($first) + $second;
  $nu = dd_nextup($dd);
  cmp_ok($nu, '==', Math::FakeDD->new($first) + ($second) + Math::FakeDD::DBL_DENORM_MIN,
                   "dd_nextup(2**$p1) + (2**$p2)) == (2**$p1) + (2**$p2) + (2 ** -1074)");
  cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$nu - $dd ok");
  $nd = dd_nextdown($dd);
  cmp_ok($nd, '==', Math::FakeDD->new($first) + ($second) - Math::FakeDD::DBL_DENORM_MIN,
                   "dd_nextdown(2**$p1) + (2**$p2)) == (2**$p1) + (2**$p2) -(2 ** -1074)");
  cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$dd - $nd ok");

  if(should_not_fail($dd)) {
    cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip");
    cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip");
  }
  else {
    warn "Skipped up-down & down-up round trip tests: " .sprintx($dd);
  }

  $first  *= -1;

  $dd = Math::FakeDD->new($first) + $second;
  $nu = dd_nextup($dd);
  cmp_ok($nu, '==', Math::FakeDD->new($first) + ($second) + Math::FakeDD::DBL_DENORM_MIN,
                   "dd_nextup(2**$p1) + (2**$p2)) == (2**$p1) + (2**$p2) + (2 ** -1074)");
  cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$nu - $dd ok");
  $nd = dd_nextdown($dd);
  cmp_ok($nd, '==', Math::FakeDD->new($first) + ($second) - Math::FakeDD::DBL_DENORM_MIN,
                   "dd_nextdown(2**$p1) + (2**$p2)) == (2**$p1) + (2**$p2) -(2 ** -1074)");
  cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$dd - $nd ok");

  if(should_not_fail($dd)) {
    cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip");
    cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip");
  }
  else {
    warn "Skipped up-down & down-up round trip tests: " .sprintx($dd);
  }

  $second *= -1;

  $dd = Math::FakeDD->new($first) + $second;
  $nu = dd_nextup($dd);
  cmp_ok($nu, '==', Math::FakeDD->new($first) + ($second) + Math::FakeDD::DBL_DENORM_MIN,
                   "dd_nextup(2**$p1) + (2**$p2)) == (2**$p1) + (2**$p2) + (2 ** -1074)");
  cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$nu - $dd ok");

  $nd = dd_nextdown($dd);
  cmp_ok($nd, '==', Math::FakeDD->new($first) + ($second) - Math::FakeDD::DBL_DENORM_MIN,
                   "dd_nextdown(2**$p1) + (2**$p2)) == (2**$p1) + (2**$p2) -(2 ** -1074)");
  cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$dd - $nd ok");

  if(should_not_fail($dd)) {
    cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip");
    cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip");
  }
  else {
    warn "Skipped up-down & down-up round trip tests: " .sprintx($dd);
  }

  $first *= -1;

  $dd = Math::FakeDD->new($first) + $second;
  $nu = dd_nextup($dd);
  cmp_ok($nu, '==', Math::FakeDD->new($first) + ($second) + Math::FakeDD::DBL_DENORM_MIN,
                   "dd_nextup(2**$p1) + (2**$p2)) == (2**$p1) + (2**$p2) + (2 ** -1074)");
  cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$nu - $dd ok");
  $nd = dd_nextdown($dd);
  cmp_ok($nd, '==', Math::FakeDD->new($first) + ($second) - Math::FakeDD::DBL_DENORM_MIN,
                   "dd_nextdown(2**$p1) + (2**$p2)) == (2**$p1) + (2**$p2) -(2 ** -1074)");
  cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$dd - $nd ok");

  if(should_not_fail($dd)) {
    cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip");
    cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip");
  }
  else {
    warn "Skipped up-down & down-up round trip tests: " .sprintx($dd);
  }

}
###############################################################################################

for(1 .. 100) {
  my $p1 = int(rand(1024));
  $p1 *= -1 if $_ % 2; # check for equal numbers of -ve and +ve powers
  my $p2 = $p1 - int(rand(52));

  my $p3 = int(rand(1024));
  $p3 *= -1 if $_ % 3;
  my $p4 = $p3 - int(rand(52));

  my $first  = 2 ** $p1;
  my $second = 2 ** $p2;
  my $third  = 2 ** $p3;
  my $fourth = 2 ** $p4;

  my $dd1 = Math::FakeDD->new($first) + $second;
  my $dd2 = Math::FakeDD->new($third) + $fourth;
  my $dd  = $dd1 + $dd2;

  my $nu = dd_nextup($dd);
  cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$nu - $dd ok");
  my $nd = dd_nextdown($dd);
  cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exponent($nd)), "$dd - $nd ok");  # ALTERED

  if(should_not_fail($dd)) {
    cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip");
    cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip");
  }
  else {
    warn "Skipped up-down & down-up round trip tests: " .sprintx($dd);
  }

  if(CHECK1 && CHECK2) { # If IVSIZE is 8 && NVTYPE is not the 80-bit extended precision long double.
    # Where possible, we establish that $dd & $nu differ by
    # 1ULP and that $dd & $nd differ by 1ULP, by doing the
    # the following:
    # Convert the hex representations of the normal mantissas
    # (ignoring the leading "(-)0x1.") to hex integers and
    # then check that those integers differ by 1ULP.
    # This check is applied only to those cases where it is valid.

    my $cmp_lsd  = ok_to_compare($dd, $nu); # This is the sub (below) that determines
                                            # whether this test can be run.
    if($cmp_lsd) {
      $sanity_checks += 2;
      cmp_ok(sanity_check($dd, $nu), '==', 1, "UP: " . sprintx($dd) . " sanity check");
      # We should also be able to do the same check with $nd.
      unless($cmp_lsd == 3) {
        cmp_ok(sanity_check($dd, $nd), '==', 1, "DN: " . sprintx($dd) . " sanity check");
      }
    }
  }

  $dd1 *= -1;

  $dd  = $dd1 + $dd2;
  $nu = dd_nextup($dd);
  $expected_exponent = ulp_exponent($dd);
  $expected_exponent-- if ($expected_exponent > -1074 && $dd->{lsd} < 0 && sprintf("%a",$dd->{lsd}) !~ /\./); # lsd < 0 && abs(lsd) is a power of 2
  cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** $expected_exponent), "$nu - $dd ok");
  $nd = dd_nextdown($dd);
  $expected_exponent = ulp_exponent($dd);
  $expected_exponent-- if ($expected_exponent > -1074 && $dd->{lsd} > 0 && sprintf("%a",$dd->{lsd}) !~ /\./); # lsd > 0 && is a power of 2
  cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** $expected_exponent), "$dd - $nd ok");

  if(should_not_fail($dd)) {
    cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip");
    cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip");
  }
  else {
    warn "Skipped up-down & down-up round trip tests: " .sprintx($dd);
  }

  if(CHECK1 && CHECK2) { # If IVSIZE is 8 && NVTYPE is not the 80-bit extended precision long double
    my $cmp_lsd  = ok_to_compare($dd, $nu);
    if($cmp_lsd) {
      $sanity_checks += 2;
      cmp_ok(sanity_check($dd, $nu), '==', 1, "UP: " . sprintx($dd) . " sanity check");
      # We should also be able to do the same check with $nd.
      unless($cmp_lsd == 3) {
        cmp_ok(sanity_check($dd, $nd), '==', 1, "DN: " . sprintx($dd) . " sanity check");
      }
    }
  }

  $dd2 *= -1;

  $dd  = $dd1 + $dd2;
  $nu = dd_nextup($dd);
  $expected_exponent = ulp_exponent($dd);
  $expected_exponent-- if ($expected_exponent > -1074 && $dd->{lsd} < 0 && sprintf("%a",$dd->{lsd}) !~ /\./); # lsd < 0 && abs(lsd) is a power of 2
  cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** $expected_exponent), "$nu - $dd ok");
  $nd = dd_nextdown($dd);
  cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$dd - $nd ok");

  if(should_not_fail($dd)) {
    cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip");
    cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip");
  }
  else {
    warn "Skipped up-down & down-up round trip tests: " .sprintx($dd);
  }

  if(CHECK1 && CHECK2) { # If IVSIZE is 8 && NVTYPE is not the 80-bit extended precision long double
    my $cmp_lsd  = ok_to_compare($dd, $nu);
    if($cmp_lsd) {
      $sanity_checks += 2;
      cmp_ok(sanity_check($dd, $nu), '==', 1, "UP: " . sprintx($dd) . " sanity check");
      # We should also be able to do the same check with $nd.
      unless($cmp_lsd == 3) {
        cmp_ok(sanity_check($dd, $nd), '==', 1, "DN: " . sprintx($dd) . " sanity check");
      }
    }
  }

  $dd1 *= -1;

  $dd  = $dd1 + $dd2;
  $nu = dd_nextup($dd);
  $expected_exponent = ulp_exponent($dd);
  $expected_exponent-- if ($expected_exponent > -1074 && $dd->{lsd} < 0 && sprintf("%a",$dd->{lsd}) !~ /\./); # lsd < 0 && abs(lsd) is a power of 2
  cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** $expected_exponent), "$nu - $dd ok");
  $nd = dd_nextdown($dd);
  $expected_exponent = ulp_exponent($dd);
  $expected_exponent-- if ($expected_exponent > -1074 && $dd->{lsd} > 0 && sprintf("%a",$dd->{lsd}) !~ /\./); # lsd > 0 && is a power of 2.
  cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** $expected_exponent), "$dd - $nd ok");

  if(should_not_fail($dd)) {
    cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip");
    cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip");
  }
  else {
    warn "Skipped up-down & down-up round trip tests: " .sprintx($dd);
  }

  if(CHECK1 && CHECK2) { # If IVSIZE is 8 && NVTYPE is not the 80-bit extended precision long double
    my $cmp_lsd  = ok_to_compare($dd, $nu);
    if($cmp_lsd) {
      $sanity_checks += 2;
      cmp_ok(sanity_check($dd, $nu), '==', 1, "UP: " . sprintx($dd) . " sanity check");
      # We should also be able to do the same check with $nd.
      unless($cmp_lsd == 3) {
        cmp_ok(sanity_check($dd, $nd), '==', 1, "DN: " . sprintx($dd) . " sanity check");
      }
    }
  }
}
###############################################################################################

my @ss = ('1' x 53, ('1' x 52) . '0', ('1' x 51) . '00', '1101' . ('1' x 49), '11101' . ('1' x 47) . '0',);
for(@ss) { die "Bad string in \@ss" if length($_) != 53 }

my @sm = ('000', '001', '010', '011', '100', '101', '110', '111',);
for(@sm) { die "Bad string in \@sm" if length($_) != 3 }

my @sf = ('0' . ('1' x 50), '1' x 51, '00'. ('1' x 49),);
for(@sf) { die "Bad string in \@sm" if length($_) != 51 }

my $mpfr = Math::MPFR::Rmpfr_init2(2098);

for(1..200) {
  my $start = $ss[int(rand(scalar(@ss)))];
  substr($start, 1 + int(rand(53)), 0, '.'); # randomly insert a radix point.
  die "starting string is of wrong length" unless length($start) == 54;
  my $middle = $sm[int(rand(scalar(@sm)))];
  my $finish = $sf[int(rand(scalar(@sf)))];

  my $mantissa = $start . $middle . $finish;
  my $exp = $_ % 2 ? 'p+' . int(rand(1024))
                   : 'p-' . int(rand(1075));

  my $binstring = $mantissa . $exp;

  Math::MPFR::Rmpfr_strtofr($mpfr, $binstring, 2, 0);

  my $dd = mpfr2dd($mpfr);
  next if dd_is_inf($dd);
  my $nu = dd_nextup($dd);
  next if dd_is_inf($nu);
  $expected_exponent = ulp_exponent($dd);
  $expected_exponent-- if ($expected_exponent > -1074 && $dd->{lsd} < 0 && sprintf("%a",$dd->{lsd}) !~ /\./); # lsd < 0 && abs(lsd) is a power of 2
  cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** $expected_exponent), "$nu - $dd ok");
  my $nd = dd_nextdown($dd);
  next if dd_is_inf($nd);
  cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$dd - $nd ok");

  if(should_not_fail($dd)) {
    cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip");
    cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip");
  }
  else {
    warn "Skipped up-down & down-up round trip tests: " .sprintx($dd);
  }

   if(CHECK1 && CHECK2) { # If IVSIZE is 8 && NVTYPE is not the 80-bit extended precision long double
    my $cmp_lsd  = ok_to_compare($dd, $nu);
    if($cmp_lsd) {
      $sanity_checks += 2;
      cmp_ok(sanity_check($dd, $nu), '==', 1, "UP: " . sprintx($dd) . " sanity check");
      # We should also be able to do the same check with $nd.
      unless($cmp_lsd == 3) {
        cmp_ok(sanity_check($dd, $nd), '==', 1, "DN: " . sprintx($dd) . " sanity check");
      }
    }
  }

  $dd *= -1;
  $nu = dd_nextup($dd);
  cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exponent($dd)), "$nu - $dd ok");
  $nd = dd_nextdown($dd);
  $expected_exponent = ulp_exponent($dd);
  $expected_exponent-- if ($expected_exponent > -1074 && $dd->{lsd} > 0 && sprintf("%a",$dd->{lsd}) !~ /\./); # lsd > 0 && is a power of 2
  cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** $expected_exponent), "$dd - $nd ok");

  if(should_not_fail($dd)) {
    cmp_ok($dd, '==', dd_nextup($nd), "up-down " . sprintx($dd) . " survives round_trip");
    cmp_ok($dd, '==', dd_nextdown($nu), "down-up " . sprintx($dd) . " survives round_trip");
  }
  else {
    warn "Skipped up-down & down-up round trip tests: " .sprintx($dd);
  }
}

warn "\n Ran $sanity_checks sanity checks${explanation}.\n";

#################
done_testing(); #
#################

sub ok_to_compare {
  # Check to see if the values enable a quick
  # sanity check to be run.
  my $d1 = $_[0]->{lsd};
  my $d2 = $_[1]->{lsd};

  # Check that they are different
  return 0 if $d1 == $d2;

  # Check that they have the same sign
  return 0 if $d1 < 0 && $d2 > 0;
  return 0 if $d1 > 0 && $d2 < 0;

  #

  # Check that they have the same exponent.
  return 0 if(split /p/i, sprintf("%a", $d1))[1]
             ne
             (split /p/i, sprintf("%a", $d2))[1];

  # Exclude testing of dd_nextdown if printf("%a", $d1) =~ /0x1p/i
  if(sprintf("%a", $d1) =~ /0x1p/i) {
    #warn  sprintx($_[0]), " ", sprintx($_[1]), "\n";
    return 3;
  }

  return 1;
}

sub sanity_check {
  #
  no warnings 'portable'; # We don't even call this sub if portability is an issue :-(
  # Check that the 2 args differ by one ULP,
  my $s1 = sprintf "%a", $_[0]->{lsd};
  my $s2 = sprintf "%a", $_[1]->{lsd};

  $s1 =~ s/0x1p/0x1.0p/i;
  $s2 =~ s/0x1p/0x1.0p/i;

  my $raw_exp1 = hex(substr(unpack("H*", pack("d>", $_[0]->{lsd})), 0, 3)) & 2047;
  my $raw_exp2 = hex(substr(unpack("H*", pack("d>", $_[1]->{lsd})), 0, 3)) & 2047;

  unless($raw_exp1 && $raw_exp2) {
    # At least one of the values is subnormal (or zero) so we just
    # go back to basics and check that the smaller of the 2 values
    # plus 2 **-1074 equals the larger value.

    if($_[0]->{lsd} > $_[1]->{lsd}) {
      return 1 if $_[1]->{lsd} + Math::FakeDD::DBL_DENORM_MIN == $_[0]->{lsd};
      return 0;
    }
    return 1 if $_[0]->{lsd} + Math::FakeDD::DBL_DENORM_MIN == $_[1]->{lsd};
    return 0;
  }

  my $h1 = (split /p/i, $s1)[0];
  $h1    = (split /\./, $h1)[1];
  {
    no warnings 'uninitialized';
    $h1 .= '0' while length($h1) < 13;
  }

  my $h2 = (split /p/i, $s2)[0];
  $h2    = (split /\./, $h2)[1];
  {
    no warnings 'uninitialized';
    $h2 .= '0' while length($h2) < 13;
  }

  $h1 = hex($h1);
  $h2 = hex($h2);
  my $diff = $h1 > $h2 ? $h1 - $h2 : $h2 - $h1;
  return 1 if $diff == 1;
  warn "VALS COMPARED: $h1 $h2\n";
  return 0;
}

sub should_not_fail {
  # TODO: remove the need for this check.
  # The values detected here will probably fail
  # the test : $dd == dd_nextup(dd_nextdown($dd))
  # and/or
  # the test: $dd == dd_nextdown(dd_nextup($dd))
  # due to a quirk in the way such values of $dd
  # are assigned.

  my $dd = shift;
  my $lsd_hex_str = sprintf("%a", $dd->{lsd});
  if($lsd_hex_str =~ /1.fffffffffffff/i) { ####
    my $ulp_exp_diff = ulp_exponent($dd, 1) - ulp_exponent($dd);
    return 0 if $ulp_exp_diff == 54;
  }
  return 1;
}

__END__

