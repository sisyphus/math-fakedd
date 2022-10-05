use strict;
use warnings;
use Math::FakeDD qw(:all);
use Config;

use constant CHECK1 => $Config{ivsize} >= 8 ? 1 : 0;

use Test::More;

*ulp_exp = \&Math::FakeDD::_ulp_exponent;
my $nan  = dd_nan();   # nan
my $pinf = dd_inf();   # +ve inf
my $ninf = dd_inf(-1); # -ve inf
my $pzero = Math::FakeDD->new(0);
my $nzero = $pzero * -1;
my $dd_denorm_min = Math::FakeDD->new(Math::FakeDD::DBL_DENORM_MIN);
my $sanity_checks = 0;

# Not sure if/how/why/when/where the values returned by
# _ulp_exponent() for Inf/NaN/Zero will matter, but let's
# check that they don't change from what I'm seeing:

cmp_ok(ulp_exp($pinf),  '==', -1074, "_ulp_exponent(inf)  returns -1074");
cmp_ok(ulp_exp($ninf),  '==', -1074, "_ulp_exponent(-inf) returns -1074");
cmp_ok(ulp_exp($nan),   '==', -1074, "_ulp_exponent(nan)  returns -1074");
cmp_ok(ulp_exp($pzero), '==', -1074, "_ulp_exponent(0)    returns -1074");
cmp_ok(ulp_exp($nzero), '==', -1074, "_ulp_exponent(-0)   returns -1074");

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

###############################################################################################
my $dd = Math::FakeDD->new(2 ** -1022) + (2 ** -1074);
# [2.225073858507202e-308 0.0]

$nu = dd_nextup($dd);
# [2.2250738585072024e-308 0.0]

cmp_ok($nu, '==', Math::FakeDD->new(2 **-1022) + (2 ** -1073),
                 "dd_nextup(2 ** -1022) + (2 ** -1074)) == (2 ** -1022) + (2 ** -1073)");
cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$nu - $dd ok");

$nd = dd_nextdown($dd);
# [2.2250738585072014e-308 0.0]

cmp_ok($nd, '==', Math::FakeDD->new(2 **-1022),
                 "dd_nextdown(2 ** -1022) + (2 ** -1074)) == (2 ** -1022)");
cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$dd - $nd ok");

$dd = Math::FakeDD->new(-(2 ** -1022)) - (2 ** -1074);
# [-2.225073858507202e-308 0.0]

$nu = dd_nextup($dd);
# [-2.2250738585072014e-308 0.0]

cmp_ok($nu, '==', Math::FakeDD->new(-(2 **-1022)),
                 "dd_nextup(-(2 ** -1022)) - (2 ** -1074)) == -(2 ** -1022)");
cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$nu - $dd ok");

$nd = dd_nextdown($dd);
# [-2.2250738585072024e-308 0.0]

cmp_ok($nd, '==', Math::FakeDD->new(-(2 **-1022)) - (2 ** -1073),
                 "dd_nextdown(-(2 ** -1022)) - (2 ** -1074)) == -(2 ** -1022) - (2 ** -1073)");
cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$dd - $nd ok");
###############################################################################################
###############################################################################################
$dd = Math::FakeDD->new(2 ** -1000) + (2 ** -1052);
# [9.33263618503219e-302 0.0]

$nu = dd_nextup($dd);
# [9.33263618503219e-302 5e-324]

cmp_ok($nu, '==', Math::FakeDD->new(2 **-1000) + (2 ** -1052) + Math::FakeDD::DBL_DENORM_MIN,
                 "dd_nextup(2 ** -1000) + (2 ** -1052)) == (2 ** -1000) + (2 ** -1052) + (2 ** -1074)");
cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$nu - $dd ok");

$nd = dd_nextdown($dd);
# [9.33263618503219e-302 -5e-324]

cmp_ok($nd, '==', Math::FakeDD->new(2 **-1000) + (2 ** -1052) - Math::FakeDD::DBL_DENORM_MIN,
                 "dd_nextdown(2 ** -1000) + (2 ** -1052)) == (2 ** -1000) + (2 ** -1052) -(2 ** -1074)");
cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$dd - $nd ok");

$dd = Math::FakeDD->new(-(2 ** -1000)) - (2 ** -1052);
# [-9.33263618503219e-302 0.0]

$nu = dd_nextup($dd);
# [-9.33263618503219e-302 5e-324]

cmp_ok($nu, '==', Math::FakeDD->new(-(2 **-1000)) - (2 ** -1052) + Math::FakeDD::DBL_DENORM_MIN,
                 "dd_nextup(-(2 ** -1000)) - (2 ** -1052)) == -(2 ** -1000) -(2 ** -1052) + (2 ** -1074)");
cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$nu - $dd ok");

$nd = dd_nextdown($dd);
# [-9.33263618503219e-302 -5e-324]

cmp_ok($nd, '==', Math::FakeDD->new(-(2 **-1000)) - (2 ** -1052)  - Math::FakeDD::DBL_DENORM_MIN,
                 "dd_nextdown(-(2 ** -1000)) - (2 ** -1052)) == -(2 ** -1000) - (2 ** -1052) -(2 ** -1074)");
cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$dd - $nd ok");
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
  cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$nu - $dd ok");
  $nd = dd_nextdown($dd);
  cmp_ok($nd, '==', Math::FakeDD->new($first) + ($second) - Math::FakeDD::DBL_DENORM_MIN,
                   "dd_nextdown(2**$p1) + (2**$p2)) == (2**$p1) + (2**$p2) -(2 ** -1074)");
  cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$dd - $nd ok");

  $first  *= -1;

  $dd = Math::FakeDD->new($first) + $second;
  $nu = dd_nextup($dd);
  cmp_ok($nu, '==', Math::FakeDD->new($first) + ($second) + Math::FakeDD::DBL_DENORM_MIN,
                   "dd_nextup(2**$p1) + (2**$p2)) == (2**$p1) + (2**$p2) + (2 ** -1074)");
  cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$nu - $dd ok");
  $nd = dd_nextdown($dd);
  cmp_ok($nd, '==', Math::FakeDD->new($first) + ($second) - Math::FakeDD::DBL_DENORM_MIN,
                   "dd_nextdown(2**$p1) + (2**$p2)) == (2**$p1) + (2**$p2) -(2 ** -1074)");
  cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$dd - $nd ok");

  $second *= -1;

  $dd = Math::FakeDD->new($first) + $second;
  $nu = dd_nextup($dd);
  cmp_ok($nu, '==', Math::FakeDD->new($first) + ($second) + Math::FakeDD::DBL_DENORM_MIN,
                   "dd_nextup(2**$p1) + (2**$p2)) == (2**$p1) + (2**$p2) + (2 ** -1074)");
  cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$nu - $dd ok");
  $nd = dd_nextdown($dd);
  cmp_ok($nd, '==', Math::FakeDD->new($first) + ($second) - Math::FakeDD::DBL_DENORM_MIN,
                   "dd_nextdown(2**$p1) + (2**$p2)) == (2**$p1) + (2**$p2) -(2 ** -1074)");
  cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$dd - $nd ok");

  $first *= -1;

  $dd = Math::FakeDD->new($first) + $second;
  $nu = dd_nextup($dd);
  cmp_ok($nu, '==', Math::FakeDD->new($first) + ($second) + Math::FakeDD::DBL_DENORM_MIN,
                   "dd_nextup(2**$p1) + (2**$p2)) == (2**$p1) + (2**$p2) + (2 ** -1074)");
  cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$nu - $dd ok");
  $nd = dd_nextdown($dd);
  cmp_ok($nd, '==', Math::FakeDD->new($first) + ($second) - Math::FakeDD::DBL_DENORM_MIN,
                   "dd_nextdown(2**$p1) + (2**$p2)) == (2**$p1) + (2**$p2) -(2 ** -1074)");
  cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$dd - $nd ok");

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
  cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$nu - $dd ok");
  my $nd = dd_nextdown($dd);
  cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$dd - $nd ok");

  $dd1 *= -1;

  $dd  = $dd1 + $dd2;
  $nu = dd_nextup($dd);
  cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$nu - $dd ok");
  $nd = dd_nextdown($dd);
  cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$dd - $nd ok");

  $dd2 *= -1;

  $dd  = $dd1 + $dd2;
  $nu = dd_nextup($dd);
  cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$nu - $dd ok");
  $nd = dd_nextdown($dd);
  cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$dd - $nd ok");

  $dd1 *= -1;

  $dd  = $dd1 + $dd2;
  $nu = dd_nextup($dd);
  cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$nu - $dd ok");
  $nd = dd_nextdown($dd);
  cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$dd - $nd ok");
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
  cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$nu - $dd ok");
  my $nd = dd_nextdown($dd);
  next if dd_is_inf($nd);
  cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$dd - $nd ok");

  if(CHECK1) { # If IVSIZE is 8
    # Where possible, establish likelihood that $dd & $nu
    #  differ by 1 ulp and that $dd & $nd differ by 1 ulp

    my $cmp_lsd  = ok_to_compare($dd, $nu);
    if($cmp_lsd) {
      $sanity_checks += 2;
      cmp_ok(sanity_check($dd, $nu), '==', 1, "UP: " . sprintx($dd) . " sanity check");
      # We should also be able to do the same check with $nd.
      cmp_ok(sanity_check($dd, $nd), '==', 1, "DN: " . sprintx($dd) . " sanity check");
    }
  }

  $dd *= -1;
  $nu = dd_nextup($dd);
  cmp_ok($nu - $dd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$nu - $dd ok");
  $nd = dd_nextdown($dd);
  cmp_ok($dd - $nd, '==', Math::FakeDD->new(2 ** ulp_exp($dd)), "$dd - $nd ok");
}

warn "\n Ran $sanity_checks sanity checks\n";

#################
done_testing(); #
#################

sub ok_to_compare {
  # Check to see if the values enable a quick
  # sanity check to be run.
  my $d1 = $_[0]->{lsd};
  my $d2 = $_[1]->{lsd};

  #my $raw_exp1 = hex(substr(unpack("H*", pack("d>", $d1)), 0, 3)) & 2047;
  #my $raw_exp2 = hex(substr(unpack("H*", pack("d>", $d2)), 0, 3)) & 2047;
  #return 0 if ($raw_exp1 == 0 || $raw_exp2 == 0);

  # Check that they are different
  return 0 if $d1 == $d2;

  # Check that they have the same sign
  return 0 if $d1 < 0 && $d2 > 0;
  return 0 if $d1 > 0 && $d2 < 0;

  # Check that they have the same exponent.
  return 0 if(split /p/i, sprintf("%a", $d1))[1]
             ne
             (split /p/i, sprintf("%a", $d2))[1];
  return 1;
}

sub sanity_check {
  #
  no warnings 'portable'; # We don't even call this sub if portability is an issue :-(
  # Check that the 2 args differ by one ULP,
  my $s1 = sprintf "%a", $_[0]->{lsd};
  my $s2 = sprintf "%a", $_[1]->{lsd};

  my $raw_exp1 = hex(substr(unpack("H*", pack("d>", $_[0]->{lsd})), 0, 3)) & 2047;
  my $raw_exp2 = hex(substr(unpack("H*", pack("d>", $_[1]->{lsd})), 0, 3)) & 2047;

  unless($raw_exp1 && $raw_exp2) {
    # At least one of the values is subnormal,and 2**-1074 may have been
    # rounded up. Therefore, we just go back to basics and check that the
    # smaller of the 2 values plus 2 **-1074 equals the larger value.

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
  print "HEX $h1 $h2\n";
  return 0;
}

__END__
[0x1.ffffffffffffdp-1009 -0x1.8p-1063]
[0x1.cp-974 -0x1.ep-1028]
[0x1.fffffffffffffp-999 -0x1.8p-1054]
[0x1.ffffffffffffcp-1001 0x1p-1056]
[0x1p-1005 -0x1.8p-1060]
[0x1.fffffffffffffp-967 -0x1.8000000000004p-1023]
[0x1p-975 -0x1.cp-1031]
[0x1.ffffffffffffcp-1018 0x1.8p-1072]
