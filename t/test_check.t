
# Check that the values that dd_repro_test uses internally are as expected.
# It's intended that additional tests will included over time.
# DBL_MIN = 2.2250738585072014e-308 = 2 ** -1022

use strict;
use warnings;
use Math::FakeDD qw(:all);
use Test::More;

for my $val(119984 .. 120006) {
  my $s = "$val" . '.0';
  my $dd = Math::FakeDD->new($s);
  cmp_ok($dd, '==', $s + 0, "$s: equivalence ok");
  my $repro = dd_repro($dd);
  cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$s: dd_repro_test ok");
  cmp_ok($s, 'eq', $Math::FakeDD::examine{repro}, "$s: \$Math::FakeDD::examine{repro} ok");
  my $chopped = "$val";
  my $exponent = 0;
  while($chopped =~ /0$/) {
    chop $chopped;
    $exponent++;
  }
  chop $chopped;
  my $inc = ($chopped + 1) . 0;
  $chopped .= 0;
  $chopped .= "e$exponent" if $exponent;
  cmp_ok($chopped, 'eq', $Math::FakeDD::examine{chop}, "$s: \$Math::FakeDD::examine{chop} ok");
  cmp_ok($inc, 'eq', (split(/e/i, $Math::FakeDD::examine{inc}))[0], "$s: \$Math::FakeDD::examine{inc} ok");
}

my $dd = Math::FakeDD->new(2 ** 150) + (2 ** -200);
my $repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "(2 ** 150) + (2 ** -200) ok");
cmp_ok('1427247692705959881058285969449495136382746624.0000000000000000000000000000000000000000000000000000000000006223015277861142',
       'eq', $Math::FakeDD::examine{repro}, "(2 ** 150) + (2 ** -200): \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('1427247692705959881058285969449495136382746624.0000000000000000000000000000000000000000000000000000000000006223015277861140',
       'eq', $Math::FakeDD::examine{chop}, "(2 ** 150) + (2 ** -200): \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('1427247692705959881058285969449495136382746624.0000000000000000000000000000000000000000000000000000000000006223015277861150e0',
       'eq', $Math::FakeDD::examine{inc}, "(2 ** 150) + (2 ** -200): \$Math::FakeDD::examine{inc} ok") ;


$dd = Math::FakeDD->new('0x1p+200') - (2 ** -549);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "(2 ** 200) - (2 ** -549) ok");
cmp_ok('1606938044258990275541962092341162602522202993782792835301375.9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999994573342896764947',
       'eq', $Math::FakeDD::examine{repro}, "(2 ** 200) - (2 ** -549): \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('1606938044258990275541962092341162602522202993782792835301375.9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999994573342896764940',
       'eq', $Math::FakeDD::examine{chop}, "(2 ** 200) - (2 ** -549): \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('1606938044258990275541962092341162602522202993782792835301375.9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999994573342896764950e0',
       'eq', $Math::FakeDD::examine{inc}, "(2 ** 200) - (2 ** -549): \$Math::FakeDD::examine{inc} ok") ;

my $str = '0.0772793798106974e-295';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('7.72793798106974e-297',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('7.72793798106970e-297',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('7.72793798106980e-297',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$str = '0.562971464820421e16';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('5629714648204210.0',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('562971464820420e1',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('562971464820430e1',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$str = '0.59951823306102625e15';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('599518233061026.25',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('599518233061026.20',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('599518233061026.30e0',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$str = '0x1.8p+982';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('61312214308906592614083769744491680749592102720577255674958251287671149318214576100913908699933768737464599967053593453894833295003451197257907357643310021232230574273057351982618758802770830966251111119192389345075122497181313138346665633846723916518618754259223225599253252973476167984984621056.0',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('61312214308906592614083769744491680749592102720577255674958251287671149318214576100913908699933768737464599967053593453894833295003451197257907357643310021232230574273057351982618758802770830966251111119192389345075122497181313138346665633846723916518618754259223225599253252973476167984984621050',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('61312214308906592614083769744491680749592102720577255674958251287671149318214576100913908699933768737464599967053593453894833295003451197257907357643310021232230574273057351982618758802770830966251111119192389345075122497181313138346665633846723916518618754259223225599253252973476167984984621060e0',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$str = '0x1p+55';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('36028797018963968.0',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('36028797018963960',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('36028797018963970e0',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$str = '0x1.8p+55';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('54043195528445952.0',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('54043195528445950',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('54043195528445960e0',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$str = '0x1.8ep+55';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('56013520365420544.0',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('56013520365420540',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('56013520365420550e0',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$str = '0x1.ep+58';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('540431955284459520.0',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('54043195528445950e1',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('54043195528445960e1',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$str = '0x1p+1006';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('685765508599211085406992031398401158759299079491541508764000248557024672719959118395646962442045349201660590667234013968119772982843080987903012964780708787451812337588750783066948774723991753080189067657794974398949244241113521123786594812548932026532556574571938698730267509225767960757581162756440064.0',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('685765508599211085406992031398401158759299079491541508764000248557024672719959118395646962442045349201660590667234013968119772982843080987903012964780708787451812337588750783066948774723991753080189067657794974398949244241113521123786594812548932026532556574571938698730267509225767960757581162756440060',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('685765508599211085406992031398401158759299079491541508764000248557024672719959118395646962442045349201660590667234013968119772982843080987903012964780708787451812337588750783066948774723991753080189067657794974398949244241113521123786594812548932026532556574571938698730267509225767960757581162756440070e0',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$str = '0x1.ffffffffffff8p+999';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('10715086071862663692576036232788416198014059957691751234372213263578972554309461602911777961568967892198733953774887693540039195621895617526639006087302044942618848719498625974407695741319177908684931242647530505452728934218200648725573819927644498709137978246274810890571754925131582314738973254090752.0',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('10715086071862663692576036232788416198014059957691751234372213263578972554309461602911777961568967892198733953774887693540039195621895617526639006087302044942618848719498625974407695741319177908684931242647530505452728934218200648725573819927644498709137978246274810890571754925131582314738973254090750',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('10715086071862663692576036232788416198014059957691751234372213263578972554309461602911777961568967892198733953774887693540039195621895617526639006087302044942618848719498625974407695741319177908684931242647530505452728934218200648725573819927644498709137978246274810890571754925131582314738973254090760e0',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$str = '0x1.8p-23';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('1.78813934326171875e-07',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('1.78813934326171870e-07',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('1.78813934326171880e-07',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

#print "INC: ", $Math::FakeDD::examine{inc}, "\n";
#print "CHOP: ", $Math::FakeDD::examine{chop}, "\n";

done_testing();


