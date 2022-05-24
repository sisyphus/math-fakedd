# Tests using values that have long runs of (implied)
# zeros or ones in their middle sections.

use strict;
use warnings;
use Math::FakeDD qw(:all);
use Test::More; # skip_all => "dd_repro() incorrectly handles some values";
use Math::FakeDD::DDTest;

#done_testing();
#__END__

*dd_mul_4196 = \&Math::FakeDD::dd_mul_4196;
*dd_add_4196 = \&Math::FakeDD::dd_add_4196;
*dd_div_4196 = \&Math::FakeDD::dd_div_4196;
*dd_sub_4196 = \&Math::FakeDD::dd_sub_4196;

my @p = (50, 100, 150, 200, 250, 300, 350, 400, 450, 500,
         550, 600, 650, 700, 750, 800, 850, 900, 950, 1000);

my(@big, @little);

for(0..19) {
  push(@big, 2 ** $p[$_]);
  push(@little, 2 ** -($p[$_]));
}

for(0..19) {
  my $xb = int(rand(20));
  my $xl = int(rand(20));
  my $yb = int(rand(20));
  my $yl = int(rand(20));
  my $ub = int(rand(20));
  my $ul = int(rand(20));
  my $vb = int(rand(20));
  my $vl = int(rand(20));

  my $x = Math::FakeDD->new( $big[$xb] ) + Math::FakeDD->new( $little[$xl] );
  my $y = Math::FakeDD->new( $big[$yb] ) + Math::FakeDD->new( $little[$yl] );

  my $u = Math::FakeDD->new( $big[$ub] ) - Math::FakeDD->new( $little[$ul] );
  my $v = Math::FakeDD->new( $big[$vb] ) - Math::FakeDD->new( $little[$vl] );

sparse_test($x, $y, $xb, $xl, $yb, $yl);
sparse_test($u, $v, $ub, -$ul, $vb, -$vl);
}

done_testing();

sub sparse_test {
  my ($op1, $op2)     = (shift, shift);
  my ($op1_b, $op1_l) = (shift, shift);
  my ($op2_b, $op2_l) = (shift, shift);
  my $repro;

  $repro = dd_repro($op1);
  chop_inc_test($op1);

  $repro = dd_repro($op2);
  chop_inc_test($op2);

  my $mul = $op1 * $op2;
  $repro = dd_repro($mul);
  chop_inc_test($mul);
  cmp_ok(Math::FakeDD->new($repro), '==', $mul, "[$op1_b $op1_l] * [$op2_b $op2_l] repro ok");
  cmp_ok($mul, '==', dd_mul_4196($op1, $op2), "$op1 * $op2 ok");

  my $add = $op1 + $op2;
  $repro = dd_repro($add);
  chop_inc_test($add);
  cmp_ok(Math::FakeDD->new($repro), '==', $add, "[$op1_b $op1_l] + [$op2_b $op2_l] repro ok");
  cmp_ok($add, '==', dd_add_4196($op1, $op2), "$op1 + $op2 ok");

  my $div = $op1 / $op2;
  $repro = dd_repro($div);
  chop_inc_test($div);
  cmp_ok(Math::FakeDD->new($repro), '==', $div, "[$op1_b $op1_l] / [$op2_b $op2_l] repro ok");
  cmp_ok($div, '==', dd_div_4196($op1, $op2), "$op1 / $op2 ok");

  my $sub = $op1 - $op2;
  $repro = dd_repro($sub);
  chop_inc_test($sub);
  cmp_ok(Math::FakeDD->new($repro), '==', $sub, "[$op1_b $op1_l] - [$op2_b $op2_l] repro ok");
  cmp_ok($sub, '==', dd_sub_4196($op1, $op2), "$op1 - $op2 ok");
}

