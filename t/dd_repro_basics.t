use strict;
use warnings;
use Math::FakeDD qw(:all);
use Test::More;

# Tests TODO

for(-1075..1024) { # -348 is the largest failing exponent in this range
  my $vp = Math::FakeDD->new(  2 ** $_) ;
  my $vn = Math::FakeDD->new(-(2 ** $_));


  my $rp = dd_repro($vp);
  my $rn = dd_repro($vn);

  ok(chop_inc_test($rp, $vp));
  ok(chop_inc_test($rn, $vn));

  if(NV_IS_DOUBLEDOUBLE) {
    ok($rp eq Math::MPFR::nvtoa($vp), "+(2 ** $_) agrees with nvtoa()");
    ok($rn eq Math::MPFR::nvtoa($vn), "-(2 ** $_) agrees with nvtoa()");
  }

  my $v1 = (2 ** $_) +
           (2 ** ($_ + 1)) +
           (2 ** ($_ + 2)) +
           (2 ** ($_ + 3));

  my $v2 = (2 ** $_) +
           (2 ** ($_ + 1));


  my $dd1 = Math::FakeDD->new($v1);
  my $dd2 = Math::FakeDD->new($v2);

  my $r1 = dd_repro($dd1);
  my $r2 = dd_repro($dd2);

  ok(chop_inc_test($r1, $dd1));
  ok(chop_inc_test($r2, $dd2));

  if(NV_IS_DOUBLEDOUBLE) {
    ok($r1 eq Math::MPFR::nvtoa($v1), "2 ** $_ + ..... agrees with nvtoa()");
    ok($r2 eq Math::MPFR::nvtoa($v2), "2 ** $_ + 2 ** ($_ + 1) agrees with nvtoa()");
  }
}

done_testing();

sub chop_inc_test {
   my $res;
   my ($repro, $op) = (shift, shift);
   if(defined($_[0])) {
     $res = dd_repro_test($repro, $op, $_[0]);
   }
   else {
     $res = dd_repro_test($repro, $op);
   }
   ok($res == 7) or dd_diag($res, $op);
}

sub dd_diag {
  print STDERR "Failed round-trip for "     . sprintx($_[1]) . " (Prec = $Math::FakeDD::REPRO_PREC)\n"
    unless $_[0] & 1;
  print STDERR "Failed chop test for "      . sprintx($_[1]) . " (Prec = $Math::FakeDD::REPRO_PREC)\n"
    unless  $_[0] & 2;
  print STDERR "Failed increment test for " . sprintx($_[1]) . " (Prec = $Math::FakeDD::REPRO_PREC)\n"
    unless $_[0] & 4;
}
