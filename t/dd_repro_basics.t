use strict;
use warnings;
use Math::FakeDD qw(:all);
use Test::More;

# Tests TODO

for(-1075..-1024) { # -348 is the largest failing exponent in this range
  my $vp = Math::FakeDD->new(  2 ** $_) ;
  my $vn = Math::FakeDD->new(-(2 ** $_));
  ok(chop_inc_test(dd_repro($vp), $vp));
  ok(chop_inc_test(dd_repro($vn), $vn));

  my $v1 = (2 ** $_) +
           (2 ** ($_ + 1)) +
           (2 ** ($_ + 2)) +
           (2 ** ($_ + 3));

  my $v2 = (2 ** $_) +
           (2 ** ($_ + 1));


  my $dd1 = Math::FakeDD->new($v1);
  my $dd2 = Math::FakeDD->new($v2);

  ok(chop_inc_test(dd_repro($dd1), $dd1));
  ok(chop_inc_test(dd_repro($dd2), $dd2));
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
