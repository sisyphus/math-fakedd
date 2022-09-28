# Run checks on dd_assign and overload_copy
use strict;
use warnings;
use Math::FakeDD qw(:all);
use Test::More;


my $obj = Math::FakeDD->new();

dd_assign($obj, 1.625);

cmp_ok($obj->{msd}, '==', 1.625, "msd == 1.625");
cmp_ok($obj->{lsd}, '==', 0, "lsd == 0");

cmp_ok(Math::MPFR::_itsa($obj->{msd}), '==', 3, "msd is NV");
cmp_ok(Math::MPFR::_itsa($obj->{lsd}), '==', 3, "lsd is NV");

dd_assign($obj, '5.125');

cmp_ok($obj->{msd}, '==', 5.125, "msd == 5.125");
cmp_ok($obj->{lsd}, '==', 0, "lsd == 0");

cmp_ok(Math::MPFR::_itsa($obj->{msd}), '==', 3, "msd is NV");
cmp_ok(Math::MPFR::_itsa($obj->{lsd}), '==', 3, "lsd is NV");

cmp_ok(dd_inf()             , '>' , 0, "dd_inf() is +ve");
cmp_ok(dd_inf(-1)           , '<' , 0, "dd_inf(-1) is -ve");
cmp_ok(dd_is_inf(dd_inf())  , '!=', 0, "+inf is recognized as inf");
cmp_ok(dd_is_inf(dd_inf(-1)), '!=', 0, "-inf is recognized as inf");
cmp_ok(dd_is_nan(dd_inf(-1)), '==', 0, "-inf is not nan"          );

cmp_ok(dd_is_nan(dd_nan())  , '!=', 0, "dd_nan() is recognized as nan");
cmp_ok(dd_is_inf(dd_nan())  , '==', 0, "nan is not inf"               );

my $x = Math::FakeDD->new(2.5);
my $y = $x;

$x *= 4;

cmp_ok($y, '==', 2.5, 'the value of the copy is unaltered');
cmp_ok($x, '==', 10, 'the original value is reset correctly');

$y = $x;
cmp_ok($y, '==', 10, 'the copy is updated correctly');

done_testing();
