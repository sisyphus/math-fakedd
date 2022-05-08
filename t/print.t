
use strict;
use warnings;
use Math::FakeDD qw(:all);

use Test::More;

my $fudd1 = Math::FakeDD->new('1e-09');

cmp_ok(dd_stringify($fudd1), 'eq', '[1e-09 -6.228159145777985e-26]'     , "decimal version of '1e-09' ok");
cmp_ok(unpackx($fudd1)     , 'eq', '[3e112e0be826d695 bab34674bfabb83b]', "'1e-09' unpacked ok"          );
cmp_ok(sprintx($fudd1)     , 'eq', '[0x1.12e0be826d695p-30 -0x1.34674bfabb83bp-84]',
                                                                       "hex representation of '1e-09' ok");

cmp_ok(dd_repro($fudd1), 'eq', '1e-09', "dd_repro() of '1e-09' ok");

cmp_ok(dd_dec($fudd1), 'eq',
       '1.0000000000000000000000000000000038785259781228752982302266735167412802775197245861511959053036235900435713119804859161376953125e-09',
        "dd_dec() of '1e-09' ok");

done_testing();
