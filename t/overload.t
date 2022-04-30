# Test overloading of various operators.
# Overloading of '+' and '+=' is tested in t/add.t
# Overloading of '-' and '-=' is tested in t/sub.t
# Overloading of '*' and '*=' is tested in t/mul.t
# Overloading of '/' and '/=' is tested in t/div.t

use strict;
use warnings;
use Math::FakeDD qw(:all);
use Test::More;

cmp_ok($Math::FakeDD::VERSION, '==', 0.01, "Version number is correct");

my $obj = Math::FakeDD->new();

dd_assign($obj, '1.3');

cmp_ok(dd_stringify($obj), 'eq', sprintf("%s", $obj), "'1.3' interpolated correctly under overloading");

dd_assign($obj, 2);

my $obj2 = dd_sqrt($obj);

cmp_ok(dd_stringify($obj2), 'eq', sprintf("%s", sqrt($obj)), "sqrt(2) interpolated correctly under overloading");

cmp_ok($obj2, '==', Math::FakeDD->new(2) ** 0.5, "overloading of sqrt() == overloaded '** 0.5'");

cmp_ok(dd_eq(dd_sqrt($obj), $obj2), '==', 1, "sqrt(2) evaluated consistently");
cmp_ok(dd_sqrt($obj), '==', $obj2, "overloading of '==' ok");
cmp_ok(dd_sqrt($obj), '!=', $obj , "overloading of '!=' ok");

my $nv = sqrt 5;

cmp_ok(($obj2 == $nv), '==', 0, "the condition obj2 == nv is false");
cmp_ok(($obj2 != $nv), '!=', 0, "the condition obj2 != nv is true" );
cmp_ok(($nv == $obj2), '==', 0, "the condition nv == obj2 is false");
cmp_ok(($nv != $obj2), '!=', 0, "the condition nv != obj2 is true" );

cmp_ok(($nv   >   $obj2),  '!=', 0, "the condition nv >= obj2 is true" );
cmp_ok(($nv   >=  $obj2),  '!=', 0, "the condition nv > obj2  is true" );
cmp_ok(($nv   <=> $obj2), '>', 0, "nv > obj2" );
cmp_ok(($obj2 <=> $nv),   '<', 0, "obj2 < nv" );

cmp_ok(Math::FakeDD->new(3) ** 0.5  , '==', 3 ** Math::FakeDD->new(0.5  ), "1:'**' overloading ok");
cmp_ok(Math::FakeDD->new(3) ** '0.6', '==', 3 ** Math::FakeDD->new('0.6'), "2:'**' overloading ok");
cmp_ok(Math::FakeDD->new(3) ** 0.6  , '==', 3 ** Math::FakeDD->new(0.6  ), "3:'**' overloading ok");

if(NV_IS_DOUBLE) {
  # Not equivalent
  cmp_ok(Math::FakeDD->new(3) ** 0.6  , '!=', 3 ** Math::FakeDD->new('0.6'), "4:'**' overloading ok");
}
if($Config::Config{nvtype} eq '__float128') {
  # Equivalent when represented as doubledoubles
  cmp_ok(Math::FakeDD->new(3) ** 0.6  , '==', 3 ** Math::FakeDD->new('0.6'), "4:'**' overloading ok");
}

my $check1 = Math::FakeDD->new(3);
$check1 **= '0.6';

cmp_ok($check1, '==', dd_pow(3, '0.6'), "'**=' overloading ok");

my $fudd1 = Math::FakeDD->new(2 ** 100);
my $fudd2 = $fudd1 + (2 ** - 100);

cmp_ok(dd_cmp($fudd1, $fudd2), '<', 0, "(2 ** 100) < (2 ** 100) + (2 **-100)");
cmp_ok(dd_cmp($fudd2, $fudd1), '>', 0, "(2 ** 100) + (2 **-100) > (2 ** 100)");

cmp_ok(dd_cmp($fudd1, -$fudd2), '>', 0, "(2 ** 100) < -(2 ** 100) - (2 **-100)");
cmp_ok(dd_cmp($fudd1, abs(-$fudd2)), '<', 0, "(2 ** 100) < abs(-(2 ** 100) + -(2 **-100))");

cmp_ok($fudd1, '==', int($fudd2), "(2 ** 100) < int((2 ** 100) + (2 **-100))");

my %oload = Math::FakeDD::oload();

cmp_ok(scalar keys(%oload), '==', 25, "Math::FakeDD::oload relative sizes ok");

done_testing();
