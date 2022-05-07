
# Check for errors due to double rounding

use warnings;
use strict;
use Math::FakeDD qw(:all);
use Test::More;

for(1..2000) {
  my $s1 = rand() . 'e' .  int(rand(10));
  my $s2 = rand() . 'e-' . int(rand(100));

  my $fudd1 = Math::FakeDD->new($s1);
  my $fudd2 = Math::FakeDD->new($s2);


  cmp_ok(dd_add($fudd1, $fudd2), '==', Math::FakeDD::dd_add_4196($fudd1, $fudd2),
                                       "ADD error with $fudd1 and $fudd2");

  cmp_ok(dd_mul($fudd1, $fudd2), '==', Math::FakeDD::dd_mul_4196($fudd1, $fudd2),
                                       "MUL error with $fudd1 and $fudd2");

  cmp_ok(dd_sub($fudd1, $fudd2), '==', Math::FakeDD::dd_sub_4196($fudd1, $fudd2),
                                       "SUB error with $fudd1 and $fudd2");

  cmp_ok(dd_div($fudd1, $fudd2), '==', Math::FakeDD::dd_div_4196($fudd1, $fudd2),
                                       "DIV error with $fudd1 and $fudd2");

}

my $m1 = Math::MPFR::Rmpfr_init2(2098);
my $m2 = Math::MPFR::Rmpfr_init2(2112);

for(1 .. 2000) {
 my $s = randbin(52) . ('0' x 2038) . randbin(13);

 Math::MPFR::Rmpfr_set_str($m1, $s, 2, 0);
 Math::MPFR::Rmpfr_set_str($m2, $s, 2, 0);

 my $first = mpfr_any_prec2dd($m2);

 cmp_ok(mpfr2dd($m1), '==', $first, "assign ..." . substr($s, -8, 8) . "ok");

 cmp_ok($first, '==', Math::FakeDD->new($s), "mpfr_any_prec2dd agrees with new()");
}

for(1 .. 2000) {
 my $s = randbin(52) . ('1' x 2038) . randbin(13);

 Math::MPFR::Rmpfr_set_str($m1, $s, 2, 0);
 Math::MPFR::Rmpfr_set_str($m2, $s, 2, 0);

 my $first = mpfr2dd($m1);

 cmp_ok($first, '==', mpfr_any_prec2dd($m2), "assign ..." . substr($s, -8, 8) . "ok");

 cmp_ok($first, '==', Math::FakeDD->new($s), "mpfr2dd agrees with new()");
}

done_testing();

sub randbin {
  my $ret = '';
  $ret .= int rand 2 for(1 .. $_[0]);
  return $ret;
}

__END__
