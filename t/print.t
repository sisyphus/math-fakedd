
use strict;
use warnings;
use Math::FakeDD qw(:all);

use Test::More;

my $fudd1 = Math::FakeDD->new('1e-09');

cmp_ok(dd_stringify($fudd1), 'eq', '[1e-09 -6.228159145777985e-26]'     , "decimal version of '1e-09' ok");
cmp_ok(unpackx($fudd1)     , 'eq', '[3e112e0be826d695 bab34674bfabb83b]', "'1e-09' unpacked ok"          );
cmp_ok(is_same_as(sprintx($fudd1), '[0x1.12e0be826d695p-30 -0x1.34674bfabb83bp-84]'), '==', 1,
                                                                       "hex representation of '1e-09' ok");
cmp_ok(dd_repro($fudd1), 'eq', '1e-09', "dd_repro() of '1e-09' ok");

cmp_ok(dd_dec($fudd1), 'eq',
       '1.0000000000000000000000000000000038785259781228752982302266735167412802775197245861511959053036235900435713119804859161376953125e-09',
        "dd_dec() of '1e-09' ok");

cmp_ok(dd_repro(dd_nan())  , 'eq', 'NaN' , "dd_repro stringifies NaN  as NaN" );
cmp_ok(dd_repro(dd_inf())  , 'eq', 'Inf' , "dd_repro stringifies +Inf as Inf" );
cmp_ok(dd_repro(dd_inf(-1)), 'eq', '-Inf', "dd_repro stringifies -Inf as -Inf");
cmp_ok(dd_repro(Math::FakeDD->new())  , 'eq', '0.0' , "dd_repro stringifies 0  as 0.0" );
cmp_ok(dd_repro(Math::FakeDD->new(1)) , 'eq', '1.0' , "dd_repro stringifies 1  as 1.0" );
cmp_ok(dd_repro(Math::FakeDD->new(-1)), 'eq', '-1.0', "dd_repro stringifies -1 as -1.0");
cmp_ok(dd_repro(Math::FakeDD->new(8)) , 'eq', '8.0' , "dd_repro stringifies 8  as 8.0" );
cmp_ok(dd_repro(Math::FakeDD->new(-8)), 'eq', '-8.0', "dd_repro stringifies -8 as -8.0");


done_testing();

sub is_same_as {
  # There's no guarantee that "%a" outputs will be as expected.
  # We check here that the represented values are identical.

  my $arg1 = shift;
  my $arg2 = shift;

  return 1 if($arg1 eq $arg2);

  my $m1 = Math::MPFR::Rmpfr_init2(53);
  my $m2 = Math::MPFR::Rmpfr_init2(53);

  $arg1 =~ s/\[|\]//g;
  $arg2 =~ s/\[|\]//g;

  my @args1 = split /\s/, $arg1;
  my @args2 = split /\s/, $arg2;

  die "Bad split in is_same_as()" if ( @args1 != 2 || @args2 != 2 );

  Math::MPFR::Rmpfr_set_str($m1, $args1[0], 0, 0);
  Math::MPFR::Rmpfr_set_str($m2, $args1[0], 0, 0);

  return 0 if $m1 != $m2;

  Math::MPFR::Rmpfr_set_str($m1, $args1[1], 0, 0);
  Math::MPFR::Rmpfr_set_str($m2, $args1[1], 0, 0);

  return 0 if $m1 != $m2;
  return 1;
}


