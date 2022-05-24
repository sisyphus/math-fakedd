package Math::FakeDD;

use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Config;

use 5.022; # for $Config{longdblkind}

use constant MPFR_LIB_VERSION   => MPFR_VERSION;

use constant NAN_COMPARE_BUG    => $Math::MPFR::VERSION < 4.23 ? 1 : 0;

use constant NV_IS_DOUBLE       => $Config{nvsize} == 8        ? 1 : 0;

use constant NV_IS_DOUBLEDOUBLE => $Config{nvsize} != 8 &&
                                   ($Config{longdblkind} >=5 && $Config{longdblkind} <= 8) ? 1 : 0;

use constant NV_IS_QUAD => $Config{nvtype} eq '__float128' ||
                           ($Config{nvtype} eq 'long double' && $Config{longdblkind} > 0
                              && $Config{longdblkind} < 3)                                 ? 1 : 0;

use constant NV_IS_80BIT_LD => $Config{nvtype} eq 'long double' &&
                               $Config{longdblkind} > 2 && $Config{longdblkind} < 5         ? 1 : 0;

use overload
'abs'   => \&dd_abs,
'atan2' => \&dd_atan2,
'bool'  => \&dd_true,
'cos'   => \&dd_cos,
'eq'    => \&dd_streq,
'ne'    => \&dd_strne,
'exp'   => \&dd_exp,
'int'   => \&dd_int,
'log'   => \&dd_log,
'sin'   => \&dd_sin,
'sqrt'  => \&dd_sqrt,
'+'     => \&dd_add,
'+='    => \&dd_add_eq,
'/'     => \&dd_div,
'/='    => \&dd_div_eq,
'=='    => \&dd_eq,
'>'     => \&dd_gt,
'>='    => \&dd_gte,
'<'     => \&dd_lt,
'<='    => \&dd_lte,
'*'     => \&dd_mul,
'*='    => \&dd_mul_eq,
'!='    => \&dd_neq,
'**'    => \&dd_pow,
'**='   => \&dd_pow_eq,
'<=>'   => \&dd_spaceship,
'""'    => \&dd_stringify,
'0+'    => \&dd_numify,
'-'     => \&dd_sub,
'-='    => \&dd_sub_eq,
'!'     => \&dd_false,
;

require Exporter;
*import = \&Exporter::import;

@Math::FakeDD::EXPORT_OK = qw(
  NV_IS_DOUBLE NV_IS_DOUBLEDOUBLE NV_IS_QUAD NV_IS_80BIT_LD MPFR_LIB_VERSION
  dd_abs dd_add dd_add_eq dd_assign dd_atan2 dd_cmp dd_cos dd_dec dd_div dd_div_eq dd_eq dd_exp
  dd_gt dd_gte dd_hex dd_inf dd_is_inf dd_is_nan dd_int dd_log dd_lt dd_lte
  dd_mul dd_mul_eq dd_nan dd_neq dd_numify dd_pow dd_pow_eq dd_repro dd_repro_test
  dd_sin dd_spaceship dd_sqrt dd_streq dd_stringify dd_strne
  dd_sub dd_sub_eq
  dd2mpfr mpfr2dd mpfr_any_prec2dd mpfr2098
  printx sprintx unpackx
);

%Math::FakeDD::EXPORT_TAGS = (all =>[@Math::FakeDD::EXPORT_OK]);

$Math::FakeDD::VERSION =  '0.04';

# Whenever dd_repro($obj) returns its string representation of
# the value of $obj, $Math::FakeDD::REPRO_PREC is set to the
# bit-precision that was used to derive that returned value.
# This variable will be set to zero if an Inf, NaN or zero
# $obj is passed to dd_repro().The initial value of -1 indicates
# that dd_repro() has not been called at all.

$Math::FakeDD::REPRO_PREC = -1;

sub new {

  my %h = ('msd' => 0, 'lsd' => 0);
  return bless(\%h) unless @_;

  if(!ref($_[0]) && $_[0] eq "Math::FakeDD") {
    # 'new' has been called as a method
    shift;
    return bless(\%h) unless @_;
  }

  die "Too many args given to new()" if @_ > 1;

  # If the remaining argument is a Math::FakeDD
  # object then simply return a copy of it:
  return shift
    if ref($_[0]) eq "Math::FakeDD";

  return mpfr2dd(mpfr2098(shift));
}

sub dd_repro {
  die "Arg given to dd_repro() must be a Math::FakeDD object"
    unless ref($_[0]) eq 'Math::FakeDD';

  my $arg = shift;
  my $prec = 0;
  if(dd_is_nan($arg)) {
    $Math::FakeDD::REPRO_PREC = 0;
    return 'NaN';
  }

  if(dd_is_inf($arg)) {
    $Math::FakeDD::REPRO_PREC = 0;
    return'Inf' if $arg > 0;
    return'-Inf';
  }

  if($arg == 0) {
    $Math::FakeDD::REPRO_PREC = 0;
    return '0.0';
  }

  my $neg = 0;
  my $mpfr = dd2mpfr($arg);
  if($mpfr < 0) {
    Rmpfr_neg($mpfr, $mpfr, MPFR_RNDN);
    $neg = 1;
  }

  my $exp = Rmpfr_get_exp($mpfr);

  if($arg->{lsd} == 0) {
    my $addon = 1074;
    if( MPFR_LIB_VERSION < 262146 ) { # 4.0.1 or earlier
      # Prior to mpfr-4.0.2, there are issues with precision < 2,
      # but DBL_DENORM_MIN calls for a precision of one bit.
      # We therefore return the hard coded value for this case.

      if($exp == -1073) {
        # $mpfr is 2 ** -1074
        my $ret = $neg ? '-5e-324' : '5e-324';
        $Math::FakeDD::REPRO_PREC = 1;
        return $ret;
      }
    }
    if($exp == -549) {
      $addon = 1073;
    }

    $prec = $addon + $exp;
    Rmpfr_prec_round($mpfr, $prec, MPFR_RNDN);

  }
  else {

    my $m_msd = Rmpfr_init2(53);
    my $m_lsd = Rmpfr_init2(53);

    Rmpfr_set_d($m_msd, $arg->{msd}, MPFR_RNDN);
    Rmpfr_set_d($m_lsd, $arg->{lsd}, MPFR_RNDN);

    if(abs($arg->{lsd}) >= 2 ** -1022) {
      # lsd is not subnormal.
      $prec = Rmpfr_get_exp($m_msd) - Rmpfr_get_exp($m_lsd) + 53;
      $prec-- if $arg->{lsd} < 0;
      my $mpfr_copy = Rmpfr_init2(2098);
      Rmpfr_set($mpfr_copy, $mpfr, MPFR_RNDN);
      Rmpfr_prec_round($mpfr_copy, $prec, MPFR_RNDN);
      my $trial_repro = mpfrtoa($mpfr_copy);
      my $trial_dd = Math::FakeDD->new($trial_repro);
      if($trial_dd == $arg || ($neg == 1 && $trial_dd == abs($arg)) ) {
        $Math::FakeDD::REPRO_PREC = $prec;
        return '-' . mpfrtoa($mpfr_copy) if $neg;
        return mpfrtoa($mpfr_copy);
      }

      $prec++;
    }
    else {
      $prec = Rmpfr_get_exp($m_msd) + 1074;
    }
    Rmpfr_prec_round($mpfr, $prec, MPFR_RNDN);
  }

  $Math::FakeDD::REPRO_PREC = $prec;
  return '-' . mpfrtoa($mpfr) if $neg;
  return mpfrtoa($mpfr);
}

sub dd_repro_test {
  my ($repro, $op) = (shift, shift);
  my $ret = 0;

  # Handle Infs, Nan, and Zero.
  if(dd_is_nan($op)) {
    return 7 if $repro =~ /^nan$/i;
    return 0;
  }

  if(dd_is_inf($op)) {
    return 7 if ($op > 0 && $repro =~ /^inf$/i);
    return 7 if ($op < 0 && $repro =~ /^\-inf$/i);
    return 0;
  }

  if($op == 0) {
    return 7 if $repro eq '0.0';
    return 0;
  }

  $repro =~ s/^\-// if $op < 0; # TODO - remove this stipulation
  $op = abs($op);               # TODO - remove this stipulation

  $ret++ if Math::FakeDD->new($repro) == $op; # round trip ok

  my @r = split /e/i, $repro;


  # We remove from $repro any trailing mantissa zeroes, and then
  # replace the least significant digit with zero.
  # IOW, we effectively chop off the least siginificant digit, thereby
  # rounding it down to the next lowest decimal precision.)
  # This altered string should assign to a DoubleDouble value that is
  # less than the given $op.

  chop($r[0]) while $r[0] =~ /0$/;
  $r[0] =~ s/\.$//;
  $r[1] = defined $r[1] ? $r[1] : 0;
  while($r[0] =~ /0$/) {
    chop $r[0];
    $r[1]++;
  }

  return $ret + 6 if length($r[0]) < 2; # chop test and increment test inapplicable.

  substr($r[0], -1, 1, '0');

  my $chopped = $r[0] . 'e' . $r[1];


  $ret += 2 if Math::FakeDD->new($chopped) < $op; # chop test ok.

  # Now we derive a value that is $repro rounded up to the next lowest
  # decimal representation.
  # This value should assign to a  DoubleDouble value that is greater
  # than the given $op.

  if($r[0] =~ /\./) {
    # We must remove the '.', do the string increment,
    # and then reinsert the '.' in the appropriate place.
    my @mantissa = split /\./, $r[0];
    my $point_pos = -(length($mantissa[1]));
    my $t = $mantissa[0] . $mantissa[1];
    $t++ for 1..10;
    substr($t, $point_pos, 0, '.');
    $r[0] = $t;
  }
  else {
    $r[0]++ for 1..10;
  }
  my $incremented = defined($r[1]) ? $r[0] . 'e' . $r[1]
                                   : $r[0];

  $ret += 4 if Math::FakeDD->new($incremented) > $op; # increment test ok
  return $ret;
}

sub _mantissa_decrement {
  # Return the given (decimal) string arg with its
  # ULP having been reduced by 1.

  my $arg = shift;
  die "Signed values not accepted in _mantissa_decrement()"
    if $arg =~ /^\+|^\-/;
  my @r = split /e/i, $arg;
  if($r[0] =~ /\./) {
    # We must remove the '.', do the string decrement,
    # and then reinsert the '.' in the appropriate place.
    my @mantissa = split /\./, $r[0];
    my $point_pos = -(length($mantissa[1]));
    my $t = $mantissa[0] . $mantissa[1];
    $t = _dec($t);
    substr($t, $point_pos, 0, '.');
    $r[0] = $t;
  }
  else {
    $r[0] = _dec($r[0]);
  }
  my $decremented = defined($r[1]) ? $r[0] . 'e' . $r[1]
                                   : $r[0];
  return $decremented;
}

sub _dec {
  my $arg = shift;

  my $sub = 1;
  my $carry = 0;
  my $pos = -1;

  while(1) {
    my $op = substr($arg, $pos, 1);
    my $rep = $op - $sub;
    if($rep < 0) {
      $rep += 10;
      $carry = 10;
    }
    else { $carry = 0 }

    substr($arg, $pos, 1, $rep);

    die "_dec() is buggy (overflowed)"
      if length $arg < -$pos;

    last unless $carry;

    $pos--;
  }

  return '0' unless $arg =~ /[1-9]/;
  $arg =~ s/^0+//;
  return $arg;

}

sub _mantissa_increment {
  # Return the given (decimal) string arg with its
  # ULP having been raised by 1.

  my $arg = shift;
  die "Signed values not accepted in _mantissa_increment()"
    if $arg =~ /^\+|^\-/;
  my @r = split /e/i, $arg;
  if($r[0] =~ /\./) {
    # We must remove the '.', do the string decrement,
    # and then reinsert the '.' in the appropriate place.
    my @mantissa = split /\./, $r[0];
    my $point_pos = -(length($mantissa[1]));
    my $t = $mantissa[0] . $mantissa[1];
    $t++ for 1..10;
    substr($t, $point_pos, 0, '.');
    $r[0] = $t;
  }
  else {
    $r[0]++ for 1..10;
  }
  my $incremented = defined($r[1]) ? $r[0] . 'e' . $r[1]
                                   : $r[0];
  return $incremented;
}

sub dd_abs {
  my $obj;
  my $ret = Math::FakeDD->new();

  if(ref($_[0]) eq 'Math::FakeDD') {
    $obj = shift;
  }
  else {
    $obj = Math::FakeDD->new(shift);
  }

  if($obj->{msd} < 0) {
    $ret->{msd} = -$obj->{msd};
    $ret->{lsd} = -$obj->{lsd};
  }
  else {
    $ret->{msd} = $obj->{msd};
    $ret->{lsd} = $obj->{lsd};
  }

  return $ret;
}

sub dd_add {
  # When dd_add is called via overloading of '+' a
  # third argument (which we CAN ignore) will be provided
  die "Wrong number of arguments given to dd_add()"
    if @_ > 3;

  my ($rop1, $rop2);

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop1 = dd2mpfr(shift);
  }
  else {
    $rop1 = mpfr2098(shift);
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr(shift);
  }
  else {
    $rop2 = mpfr2098(shift);
  }

  Rmpfr_add($rop1, $rop1, $rop2, MPFR_RNDN);
  return mpfr2dd($rop1);

}

sub dd_add_4196 {
  # Used only in testing.
  die "Wrong number of arguments given to dd_add()"
    if @_ > 2;

  my ($rop1, $rop2);

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop1 = dd2mpfr(shift);
  }
  else {
    $rop1 = mpfr2098(shift);
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr(shift);
  }
  else {
    $rop2 = mpfr2098(shift);
  }

  my $ret = Rmpfr_init2(4196);

  Rmpfr_add($ret, $rop1, $rop2, MPFR_RNDN);
  return mpfr_any_prec2dd($ret);

}

sub dd_add_eq {
  # When dd_add_eq is called via overloading of '+=' a
  # third argument (which we CAN ignore) will be provided
  die "Wrong number of arguments given to dd_add_eq()"
    if @_ > 3;

  my ($rop1, $rop2);

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop1 = dd2mpfr($_[0]);
  }
  else {
    die "First arg to dd_add_eq must be a Math::FakeDD object";
  }

  if(ref($_[1]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr($_[1]);
  }
  else {
    $rop2 = mpfr2098($_[1]);
  }

  Rmpfr_add($rop1, $rop1, $rop2, MPFR_RNDN);

  if(@_ > 2) {
    # dd_add_eq() has been called via
    # Math::FakeDD overloading of '+='.
    return mpfr2dd($rop1);
  }

  dd_assign($_[0], mpfr2dd($rop1));
}

sub dd_assign {
  die "Wrong number of arguments given to dd_assign()"
    unless @_ == 2;

  die "First arg to dd_assign must be a Math::FakeDD object"
    unless ref($_[0]) eq 'Math::FakeDD';

  my $val = $_[1];
  if(ref($val) eq 'Math::FakeDD') {
    $_[0]->{msd} = $val->{msd};
    $_[0]->{lsd} = $val->{lsd};
  }
  else {
    my $obj = mpfr2dd(mpfr2098($val));
    $_[0]->{msd} = $obj->{msd};
    $_[0]->{lsd} = $obj->{lsd};
  }
}

sub dd_atan2 {

  # When dd_atan2 is called via overloading of 'atan2' a
  # third argument (which we cannot ignore) will be provided
  die "Wrong number of arguments given to dd_add()"
    if @_ > 3;

  my ($rop1, $rop2);

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop1 = dd2mpfr(shift);
  }
  else {
    $rop1 = mpfr2098(shift);
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr(shift);
  }
  else {
    $rop2 = mpfr2098(shift);
  }

  if(@_ && $_[0]) { # switch args
    Rmpfr_atan2($rop2, $rop2, $rop1, MPFR_RNDN);
    return mpfr2dd($rop2);
  }

  Rmpfr_atan2($rop1, $rop1, $rop2, MPFR_RNDN);
  return mpfr2dd($rop1);
}


sub dd_cmp {

  die "Wrong number of arguments given to dd_cmp()"
    unless @_ == 2;

  my ($rop1, $rop2);

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop1 = dd2mpfr(shift);
  }
  else {
    $rop1 = dd2mpfr(Math::FakeDD->new(shift));
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr(shift);
  }
  else {
    $rop2 = dd2mpfr(Math::FakeDD->new(shift));
  }

  return $rop1 <=> $rop2; # "<=>" is "Math::MPFR::overload_spaceship"
                          # and will return undef if a NaN is involved.
}

sub dd_cos {
  my $obj;
  if(ref($_[0]) eq 'Math::FakeDD') { $obj = shift }
  else {
    $obj = Math::FakeDD->new(shift);
  }
  my $ret = Math::FakeDD->new();
  my $mpfr = Rmpfr_init2(2098);
  Rmpfr_cos($mpfr, dd2mpfr($obj), MPFR_RNDN);
  $obj = mpfr2dd($mpfr);
  $ret->{msd} = $obj->{msd};
  $ret->{lsd} = $obj->{lsd};
  return $ret;
}

sub dd_dec {
  die "Wrong arg given to dd_dec()"
    unless ref($_[0]) eq 'Math::FakeDD';
  my $mpfr = dd2mpfr(shift);

  if(!Rmpfr_regular_p($mpfr)) {
    return '0.0'   if Rmpfr_zero_p($mpfr);
    return 'NaN' if Rmpfr_nan_p($mpfr);

    # must be an inf
    return 'Inf' if $mpfr > 0;
    return '-Inf';
  }

  return decimalize($mpfr);
}

sub dd_div {
  # When dd_div is called via overloading of '/' a
  # third argument (which we cannot ignore) will be provided
  die "Wrong number of arguments given to dd_div()"
    if @_ > 3;

  my ($rop1, $rop2);

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop1 = dd2mpfr(shift);
  }
  else {
    $rop1 = mpfr2098(shift);
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr(shift);
  }
  else {
    $rop2 = mpfr2098(shift);
  }

  if(@_ && $_[0]) { # switch args
    Rmpfr_div($rop2, $rop2, $rop1, MPFR_RNDN);
    return mpfr2dd($rop2);
  }
  Rmpfr_div($rop1, $rop1, $rop2, MPFR_RNDN);
  return mpfr2dd($rop1);

}

sub dd_div_4196 {
  # Used only in testing.
  die "Wrong number of arguments given to dd_div()"
    if @_ > 2;

  my ($rop1, $rop2);

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop1 = dd2mpfr(shift);
  }
  else {
    $rop1 = mpfr2098(shift);
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr(shift);
  }
  else {
    $rop2 = mpfr2098(shift);
  }

  my $ret = Rmpfr_init2(4196);

  Rmpfr_div($ret, $rop1, $rop2, MPFR_RNDN);
  return mpfr_any_prec2dd($ret);

}

sub dd_div_eq {
  # When dd_div_eq is called via overloading of '/=' a
  # third argument (which we CAN ignore) will be provided
  die "Wrong number of arguments given to dd_div_eq()"
    if @_ > 3;

  my ($rop1, $rop2);

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop1 = dd2mpfr($_[0]);
  }
  else {
    die "First arg to dd_div_eq must be a Math::FakeDD object";
  }

  if(ref($_[1]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr($_[1]);
  }
  else {
    $rop2 = mpfr2098($_[1]);
  }

  Rmpfr_div($rop1, $rop1, $rop2, MPFR_RNDN);

  if(@_ > 2) {
    # dd_div_eq() has been called via
    # Math::FakeDD overloading of '/='.
    return mpfr2dd($rop1);
  }
  dd_assign($_[0], mpfr2dd($rop1));

}

sub dd_eq {

  # When dd_eq is called via overloading of '==' a
  # third argument (which we CAN ignore) will be provided
  die "Wrong number of args passed to dd_eq()"
    if(@_ > 3);
  my $cmp = dd_cmp(shift, shift);
  return 0 if $cmp || !defined $cmp; # not equal
  return 1;                          # equal
}

sub dd_exp {
  my $obj;
  if(ref($_[0]) eq 'Math::FakeDD') { $obj = shift }
  else {
    $obj = Math::FakeDD->new(shift);
  }
  my $ret = Math::FakeDD->new();
  my $mpfr = Rmpfr_init2(2098);
  Rmpfr_exp($mpfr, dd2mpfr($obj), MPFR_RNDN);
  $obj = mpfr2dd($mpfr);
  $ret->{msd} = $obj->{msd};
  $ret->{lsd} = $obj->{lsd};
  return $ret;
}

sub dd_gt {

  # When dd_gt is called via overloading of '>' a third
  # argument (which we cannot ignore) will be provided
  die "Wrong number of args passed to dd_gt()"
    if(@_ > 3);

  my $correction = 1;
  $correction = -1
    if (@_ == 3 && $_[2]);

  return 1 if $correction * dd_cmp(shift, shift) > 0; # greater than
  return 0;                                           # not greater than
}

sub dd_gte {

  # When dd_gte is called via overloading of '>=' a third
  # argument (which we cannot ignore) will be provided
  die "Wrong number of args passed to dd_gte()"
    if(@_ > 3);

  my $correction = 1;
  $correction = -1
    if (@_ == 3 && $_[2]);

  return 0 if $correction * dd_cmp(shift, shift) < 0; # less than
  return 1;                                           # greater than or equal
}

sub dd_hex {
  die "Wrong arg given to dd_dec()"
    unless ref($_[0]) eq 'Math::FakeDD';

  my $mpfr = dd2mpfr(shift);

  if(!Rmpfr_regular_p($mpfr)) {
    return '0x0p+0'   if Rmpfr_zero_p($mpfr);
    return 'NaN' if Rmpfr_nan_p($mpfr);

    # must be an inf
    return 'Inf' if $mpfr > 0;
    return '-Inf';
  }

  my $buffer;
  Rmpfr_sprintf($buffer, "%Ra", $mpfr, 528);

  return $buffer;
}

sub dd_int {
  # Don't fall for the idea that we can just do int(msd), int(lsd)
  # when $_[0] is a Math::FakeDD object. I tried that and it doesn't
  # work when, eg, the Math::FakeDD object has been assigned a (string)
  # value of "0.59943243884210417e16".

  my $obj;
  if(ref($_[0]) eq 'Math::FakeDD') { $obj = shift }
  else {
    $obj = Math::FakeDD->new(shift);
  }
  my $ret = Math::FakeDD->new();
  my $mpfr = Rmpfr_init2(2098);
  Rmpfr_trunc($mpfr, dd2mpfr($obj));
  $obj = mpfr2dd($mpfr);
  $ret->{msd} = $obj->{msd};
  $ret->{lsd} = $obj->{lsd};
  return $ret;
}

sub dd_log {
  my $obj;
  if(ref($_[0]) eq 'Math::FakeDD') { $obj = shift }
  else {
    $obj = Math::FakeDD->new(shift);
  }
  my $ret = Math::FakeDD->new();
  my $mpfr = Rmpfr_init2(2098);
  Rmpfr_log($mpfr, dd2mpfr($obj), MPFR_RNDN);
  $obj = mpfr2dd($mpfr);
  $ret->{msd} = $obj->{msd};
  $ret->{lsd} = $obj->{lsd};
  return $ret;
}

sub dd_lt {

  # When dd_gt is called via overloading of '<' a third
  # argument (which we cannot ignore) will be provided
  die "Wrong number of args passed to dd_lt()"
    if(@_ > 3);

  my $correction = 1;
  $correction = -1
    if (@_ == 3 && $_[2]);

  return 1 if $correction * dd_cmp(shift, shift) < 0; # less than
  return 0;                                           # not less than
}

sub dd_lte {

  # When dd_lte is called via overloading of '>=' a third
  # argument (which we cannot ignore) will be provided
  die "Wrong number of args passed to dd_lte()"
    if(@_ > 3);

  my $correction = 1;
  $correction = -1
    if (@_ == 3 && $_[2]);

  return 0 if $correction * dd_cmp(shift, shift) > 0; # greater than
  return 1;                                           # less than or equal
}

sub dd_mul {
  # When dd_mul is called via overloading of '*' a
  # third argument (which we CAN ignore) will be provided
  die "Wrong number of arguments given to dd_mul()"
    if @_ > 3;

  my ($rop1, $rop2);

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop1 = dd2mpfr(shift);
  }
  else {
    $rop1 = mpfr2098(shift);
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr(shift);
  }
  else {
    $rop2 = mpfr2098(shift);
  }

  Rmpfr_mul($rop1, $rop1, $rop2, MPFR_RNDN);
  return mpfr2dd($rop1);

}

sub dd_mul_4196 {
  # Used only in testing.
  die "Wrong number of arguments given to dd_mul()"
    if @_ > 2;

  my ($rop1, $rop2);

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop1 = dd2mpfr(shift);
  }
  else {
    $rop1 = mpfr2098(shift);
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr(shift);
  }
  else {
    $rop2 = mpfr2098(shift);
  }

  my $ret = Rmpfr_init2(4196);

  Rmpfr_mul($ret, $rop1, $rop2, MPFR_RNDN);
  return mpfr_any_prec2dd($ret);

}

sub dd_mul_eq {
  # When dd_mul_eq is called via overloading of '*=' a
  # third argument (which we CAN ignore) will be provided
  die "Wrong number of arguments given to dd_mul_eq()"
    if @_ > 3;

  my ($rop1, $rop2);

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop1 = dd2mpfr($_[0]);
  }
  else {
    die "First arg to dd_mul_eq must be a Math::FakeDD object";
  }

  if(ref($_[1]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr($_[1]);
  }
  else {
    $rop2 = mpfr2098($_[1]);
  }

  Rmpfr_mul($rop1, $rop1, $rop2, MPFR_RNDN);

  if(@_ > 2) {
    # dd_mul_eq() has been called via
    # Math::FakeDD overloading of '*='.
    return mpfr2dd($rop1);
  }

  dd_assign($_[0], mpfr2dd($rop1));
}

sub dd_neq {

  # When dd_neq is called via overloading of '!=' a
  # third argument (which we CAN ignore) will be provided
  die "Wrong number of args passed to dd_neq()"
    if(@_ > 3);
  my $cmp = dd_cmp(shift, shift);
  return 1 if $cmp || !defined $cmp; # not equal
  return 0;                          # equal
}

sub dd_numify {
  # Mainly for '0+' overloading.
  die "Argument passed to dd_numify must ge a Math::FakeDD object"
    unless ref($_[0]) eq 'Math::FakeDD';

  my $arg = shift;
  return $arg->{msd} + $arg->{lsd}; # Information might be lost if
                                    # NV type is not DoubleDouble.
}

sub dd_pow {
  # When dd_pow is called via overloading of '**' a
  # third argument (which we cannot ignore) will be provided
  die "Wrong number of arguments given to dd_pow()"
    if @_ > 3;

  my ($rop1, $rop2);

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop1 = dd2mpfr(shift);
  }
  else {
    $rop1 = mpfr2098(shift);
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr(shift);
  }
  else {
    $rop2 = mpfr2098(shift);
  }

  if(@_ && $_[0]) { # switch args
    Rmpfr_pow($rop2, $rop2, $rop1, MPFR_RNDN);
    return mpfr2dd($rop2);
  }
  Rmpfr_pow($rop1, $rop1, $rop2, MPFR_RNDN);
  return mpfr2dd($rop1);

}

sub dd_pow_eq {
  # When dd_pow_eq is called via overloading of '**=' a
  # third argument (which we CAN ignore) will be provided
  die "Wrong number of arguments given to dd_pow_eq()"
    if @_ > 3;

  my ($rop1, $rop2);

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop1 = dd2mpfr($_[0]);
  }
  else {
    die "First arg to dd_pow_eq must be a Math::FakeDD object";
  }

  if(ref($_[1]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr($_[1]);
  }
  else {
    $rop2 = mpfr2098($_[1]);
  }

  Rmpfr_pow($rop1, $rop1, $rop2, MPFR_RNDN);

  if(@_ > 2) {
    # dd_pow_eq() has been called via
    # Math::FakeDD overloading of '**='.
    return mpfr2dd($rop1);
  }

  dd_assign($_[0], mpfr2dd($rop1));
}

sub dd_sin {
  my $obj;
  if(ref($_[0]) eq 'Math::FakeDD') { $obj = shift }
  else {
    $obj = Math::FakeDD->new(shift);
  }
  my $ret = Math::FakeDD->new();
  my $mpfr = Rmpfr_init2(2098);
  Rmpfr_sin($mpfr, dd2mpfr($obj), MPFR_RNDN);
  $obj = mpfr2dd($mpfr);
  $ret->{msd} = $obj->{msd};
  $ret->{lsd} = $obj->{lsd};
  return $ret;
}

sub dd_spaceship {

  # When dd_spaceship is called via overloading of '<=>' a
  # third argument (which we cannot ignore) will be provided
  die "Wrong number of args passed to dd_spaceship()"
    if(@_ > 3);

  my $correction = 1;
  $correction = -1
    if (@_ == 3 && $_[2]);

  my($arg1, $arg2) = (shift, shift);

  if(NAN_COMPARE_BUG) { # Fixed in Math-MPFR-4.23 and later.
    if(dd_is_nan(Math::FakeDD->new($arg1)) || dd_is_nan(Math::FakeDD->new($arg2))) {
      return undef;
    }
  }

  my $cmp = dd_cmp($arg1, $arg2);
  return $correction * $cmp if defined $cmp;
  return $cmp;
}

sub dd_sqrt {
  my $obj;
  if(ref($_[0]) eq 'Math::FakeDD') { $obj = shift }
  else {
    $obj = Math::FakeDD->new(shift);
  }
  my $ret = Math::FakeDD->new();
  my $mpfr = Rmpfr_init2(2098);
  Rmpfr_sqrt($mpfr, dd2mpfr($obj), MPFR_RNDN);

  $obj = mpfr2dd($mpfr);
  $ret->{msd} = $obj->{msd};
  $ret->{lsd} = $obj->{lsd};
  return $ret;
}

sub dd_streq {
  # Provided only because Test::More can pull in code
  # that assumes that overloading of 'eq' exists.
  # This is the function that overloaded 'eq' calls.
  die "Wrong arg given to dd_streq()"
    unless ref($_[0]) eq 'Math::FakeDD';

  my($arg1, $arg2) = (shift, shift);
  return 1 if "$arg1" eq "$arg2";
  return 0;
}

sub dd_strne {
  # Provided only because dd_streq() is provided.
  die "Wrong arg given to dd_strne()"
    unless ref($_[0]) eq 'Math::FakeDD';

  my($arg1, $arg2) = (shift, shift);
  return 1 if "$arg1" ne "$arg2";
  return 0;
}

sub dd_stringify {
  die "Wrong arg given to dd_stringify()"
    unless ref($_[0]) eq 'Math::FakeDD';

  my $self = shift;
  my($mpfrm, $mpfrl) = (Rmpfr_init2(53), Rmpfr_init2(53));
  Rmpfr_set_d($mpfrm, $self->{msd}, MPFR_RNDN);
  Rmpfr_set_d($mpfrl, $self->{lsd}, MPFR_RNDN);
  return "[" . mpfrtoa($mpfrm) . " " . mpfrtoa($mpfrl) . "]";
}

sub dd_sub {
  # When dd_sub is called via overloading of '-' a
  # third argument (which we cannot ignore) will be provided
  die "Wrong number of arguments given to dd_sub()"
    if @_ > 3;

  my ($rop1, $rop2);

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop1 = dd2mpfr(shift);
  }
  else {
    $rop1 = mpfr2098(shift);
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr(shift);
  }
  else {
    $rop2 = mpfr2098(shift);
  }

  if(@_ && $_[0]) { # switch args
    Rmpfr_sub($rop2, $rop2, $rop1, MPFR_RNDN);
    return mpfr2dd($rop2);
  }

  Rmpfr_sub($rop1, $rop1, $rop2, MPFR_RNDN);
  return mpfr2dd($rop1);
}

sub dd_sub_4196 {
  # Used only in testing.
  die "Wrong number of arguments given to dd_sub()"
    if @_ > 2;

  my ($rop1, $rop2);

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop1 = dd2mpfr(shift);
  }
  else {
    $rop1 = mpfr2098(shift);
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr(shift);
  }
  else {
    $rop2 = mpfr2098(shift);
  }

  my $ret = Rmpfr_init2(4196);

  Rmpfr_sub($ret, $rop1, $rop2, MPFR_RNDN);
  return mpfr_any_prec2dd($ret);
}

sub dd_sub_eq {
  # When dd_sub_eq is called via overloading of '-=' a
  # third argument (which we CAN ignore) will be provided
  die "Wrong number of arguments given to dd_sub_eq()"
    if @_ > 3;

  my ($rop1, $rop2);

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop1 = dd2mpfr($_[0]);
  }
  else {
    die "First arg to dd_sub_eq must be a Math::FakeDD object";
  }

  if(ref($_[1]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr($_[1]);
  }
  else {
    $rop2 = mpfr2098($_[1]);
  }

  Rmpfr_sub($rop1, $rop1, $rop2, MPFR_RNDN);

  if(@_ > 2) {
    # dd_sub_eq() has been called via
    # Math::FakeDD overloading of '-='.
    return mpfr2dd($rop1);
  }

  dd_assign($_[0], mpfr2dd($rop1));

}

sub dd2mpfr {
  my $self = shift;
  my $ret = Rmpfr_init2(2098);
  Rmpfr_add($ret, mpfr2098($self->{msd}), mpfr2098($self->{lsd}), MPFR_RNDN);
  return $ret;
}

sub mpfr2dd {
  my %h;

  die "Arg given to mpfr2dd() must be a Math::MPFR object"
    unless ref($_[0]) eq 'Math::MPFR';

  # mpfr2dd() will handle an argument of any precision - but if the
  # precision is not 2098, then it's probably a mistake. So let's
  # disallow it until it becomes evident that it should be permitted.

  die "Precision of Math::MPFR object passed to mpfr2dd() must be 2098"
    unless Rmpfr_get_prec($_[0]) == 2098;

  my $mpfr = Rmpfr_init2(2098);
  Rmpfr_set($mpfr, shift, MPFR_RNDN);

  my $msd = Rmpfr_get_d($mpfr, MPFR_RNDN);
  if($msd == 0 || $msd != $msd || $msd / $msd != 1) { # $msd is zero, nan, or inf.
    $h{msd} = $msd;
    $h{lsd} = 0;
    return bless(\%h);
  }
  Rmpfr_sub_d($mpfr, $mpfr, $msd, MPFR_RNDN);
  my $lsd = Rmpfr_get_d($mpfr, MPFR_RNDN);
  $h{msd} = $msd;
  $h{lsd} = $lsd;
  return bless(\%h);
}

sub mpfr_any_prec2dd {
  # Converts a Math::MPFR object of any
  # precision to a Math::FakeDD object.
  my %h;

  die "Arg given to mpfr2dd() must be a Math::MPFR object"
    unless ref($_[0]) eq 'Math::MPFR';

  my $prec_in = Rmpfr_get_prec($_[0]);
  my $mpfr_prec = $prec_in <= 2098 ? 2098 : $prec_in;

  my $mpfr = Rmpfr_init2($mpfr_prec);
  Rmpfr_set($mpfr, shift, MPFR_RNDN);

  my $msd = Rmpfr_get_d($mpfr, MPFR_RNDN);
  if($msd == 0 || $msd != $msd || $msd / $msd != 1) { # $msd is zero, nan, or inf.
    $h{msd} = $msd;
    $h{lsd} = 0;
    return bless(\%h);
  }

  Rmpfr_sub_d($mpfr, $mpfr, $msd, MPFR_RNDN);
  my $lsd = Rmpfr_get_d($mpfr, MPFR_RNDN);
  $h{msd} = $msd;
  $h{lsd} = $lsd;
  return bless(\%h);
}

sub mpfr2098 {
  # Set the argument to a 2098-bit precision Math::MPFR object.
  my $ret = Rmpfr_init2(2098);
  my $itsa = Math::MPFR::_itsa($_[0]);

  # Arg must be one of PV (string), IV (integer), UV (unsigned integer),
  # NV (perl floating point type) or Math::MPFR object.

  die "Invalid arg ($itsa) passed internally to mpfr2098()"
    unless ($itsa > 0 && $itsa <= 4);

  my $arg = shift;

  if($itsa == 4) {                           # PV
    Rmpfr_set_str($ret, $arg, 0, MPFR_RNDN);
    return $ret;
  }

  if($itsa == 3) {                           # NV
    Rmpfr_set_NV($ret, $arg, MPFR_RNDN);
    return $ret;
  }

  Rmpfr_set_IV($ret, $arg, MPFR_RNDN);       # IV/UV
  return $ret;

}

sub oload {
  # Not exported.
  # Return a list of the operator-function pairs for the overloaded
  # operators and the respective functions that they call.

  my %h = (
    'abs'   => 'dd_abs',
    'atan2' => 'dd_atan2',
    'bool'  => 'dd_true',
    'cos'   => 'dd_cos',
    'eq'    => 'dd_streq',
    'ne'    => 'dd_strne',
    'exp'   => 'dd_exp',
    'int'   => 'dd_int',
    'log'   => 'dd_log',
    'sin'   => 'dd_sin',
    'sqrt'  => 'dd_sqrt',
    '+'     => 'dd_add',
    '+='    => 'dd_add_eq',
    '/'     => 'dd_div',
    '/='    => 'dd_div_eq',
    '=='    => 'dd_eq',
    '>'     => 'dd_gt',
    '>='    => 'dd_gte',
    '<'     => 'dd_lt',
    '<='    => 'dd_lte',
    '*'     => 'dd_mul',
    '*='    => 'dd_mul_eq',
    '!='    => 'dd_neq',
    '**'    => 'dd_pow',
    '**='   => 'dd_pow_eq',
    '<=>'   => 'dd_spaceship',
    '""'    => 'dd_stringify',
    '0+'    => 'dd_numify',
    '-'     => 'dd_sub',
    '-='    => 'dd_sub_eq',
    '!'     => 'dd_false',
);

  return %h
}

sub dd_true {
  die "Not a Math::FakeDD object passed to dd_true()"
    unless ref($_[0]) eq 'Math::FakeDD';

  return 1 if(dd2mpfr(shift)); # Uses Math::MPFR overloading of 'bool'
  return 0;
}

sub dd_false {
  die "Not a Math::FakeDD object passed to dd_false()"
    unless ref($_[0]) eq 'Math::FakeDD';

  return 1 if !(dd2mpfr(shift)); # Uses Math::MPFR overloading of '!'
  return 0;
}

sub dd_is_inf {
  die "Not a Math::FakeDD object passed to dd_is_inf()"
    unless ref($_[0]) eq 'Math::FakeDD';

  return 1 if Rmpfr_inf_p(Math::MPFR->new($_[0]->{msd}));
  return 0;
}

sub dd_is_nan {
  die "Not a Math::FakeDD object passed to dd_is_nan()"
    unless ref($_[0]) eq 'Math::FakeDD';

  return 1 if Rmpfr_nan_p(Math::MPFR->new($_[0]->{msd}));
  return 0;
}

sub dd_inf {
  my $inf = Math::MPFR->new();
  Rmpfr_set_inf($inf, defined($_[0]) ?  shift : 0); # Will be -Inf only if $_[0] < 0
  my %h = (msd => Rmpfr_get_d($inf, MPFR_RNDN), lsd => 0.0);
  return bless \%h;
}

sub dd_nan {
  my %h = (msd => Rmpfr_get_d(Math::MPFR->new(), MPFR_RNDN), lsd => 0.0);
  return bless \%h;
}

sub printx {
  print sprintx(shift);
}

sub sprintx {
  if(ref($_[0]) eq 'Math::FakeDD') {
    my $self = shift;
    return "[" . sprintf("%a", $self->{msd}) . " " . sprintf("%a", $self->{lsd}) . "]";
  }
  die "Wrong arg given to sprintx()";
}

sub unpackx {
  if(ref($_[0]) eq 'Math::FakeDD') {
    my $self = shift;
    return "[" . unpack("H*", pack("d>", $self->{msd})) . " " . unpack("H*", pack("d>", $self->{lsd})) . "]";
  }
  die "Wrong arg given to unpackx()";
}

1;

