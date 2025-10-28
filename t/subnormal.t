use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Config;

use Math::FakeDD qw(:all);

use Test::More;

if($Config{nvsize} != 8 ) {
  cmp_ok(1, '==', 1, 'dummy test');
  warn "Skipping tests because nvsize is greater than 8";
  done_testing();
  exit 0;
}

if($Math::MPFR::VERSION < 4.44 ) {
  cmp_ok(1, '==', 1, 'dummy test');
  warn "Skipping tests because Math::MPFR version ($Math::MPFR::VERSION) needs to be at 4.44 or greater";
  done_testing();
  exit 0;
}

my @pow = (1023 .. 1074);

for(1..500) {
  my $arg = 0;
  my $how_many = 2 + int(rand(10));

  for(1 .. $how_many) {
    $arg += 2 ** -($pow[int(rand(51))]);
  }
  cmp_ok(nvtoa($arg), '==', mpfrtoa(Math::MPFR->new($arg)), "$arg - strings numify equivalently");
  # mpfrtoa() does not yet reduce subnormal values to their correct (minimum) precision,
  # so we skip the following test for now.
  # When (if) I fix mpfrtoa to allow for subnormalization, we'll also need to stringify $arg accurately:
  # my $mpfr_temp = Math::MPFR->new($arg);
  # cmp_ok(nvtoa($arg), 'eq', mpfrtoa(Math::MPFR::subnormalize_generic("$mpfr_temp", -1073, 1024, 53)), "$arg - strings are identical");
}

my($dd1, $dd2, $dd3, $dd4) = ( Math::FakeDD->new(2.01) ** -505, Math::FakeDD->new(2.01) ** -520,
                               Math::FakeDD->new(2.01) ** 505, Math::FakeDD->new(2.01) ** 520 );

#print "$dd1\n"; # [7.691145062557722e-154 5.891394197874965e-170]
#print "$dd2\n"; # [2.177961213729931e-158 -1.7775114692278932e-174]
#print $dd1 ** 2, "\n"; [5.915371237330603e-307 5e-324]
#print $dd2 ** 2, "\n"; [4.74351503e-316 0.0]

cmp_ok($dd1 ** 2, '==', $dd1 * $dd1,          '$dd1 ** 2 == $dd1 * $dd1');
cmp_ok($dd1 ** 2, '==', $dd1 / $dd3,          '$dd1 ** 2 == $dd1 / $dd3');

cmp_ok($dd2 ** 2, '==', $dd2 * $dd2,          '$dd2 ** 2 == $dd2 * $dd2');
cmp_ok($dd2 ** 2, '==', $dd2 / $dd4,          '$dd2 ** 2 == $dd2 / $dd4');

my $sq_subn = $dd2 ** 2;
cmp_ok($sq_subn->{lsd}, '==', 0, '$sq_subn->{lsd} is 0');

$dd1 *= $dd2;
cmp_ok($dd1->{lsd}, '==', 0, '$dd1->{lsd} has changed to 0');

$sq_subn += 2.01 ** -1041;
#print "$sq_subn\n";  [7.10347275e-316 0.0]
cmp_ok($sq_subn->{lsd}, '==', 0, '$sq_subn->{lsd} is still 0');

my $sq_subn_retrieved = $sq_subn - (2.01 ** -1041);
cmp_ok($sq_subn_retrieved, '==', $dd2 ** 2, 'Original value retrieved');

done_testing();
