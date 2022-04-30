package Math::FakeDD;

use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Config;

use constant NV_IS_DOUBLE       => $Config{nvsize} == 8 ? 1 : 0;
use constant NV_IS_DOUBLEDOUBLE => $Config{nvsize} != 8 &&
                                   ($Config{longdblkind} >=5 && $Config{longdblkind} <= 8) ? 1 : 0;

use overload
'abs'  => \&dd_abs,
'cos'  => \&dd_cos,
'exp'  => \&dd_exp,
'int'  => \&dd_int,
'log'  => \&dd_log,
'sin'  => \&dd_sin,
'sqrt' => \&dd_sqrt,
'+'    => \&dd_add,
'+='   => \&dd_add_eq,
'/'    => \&dd_div,
'/='   => \&dd_div_eq,
'=='   => \&dd_eq,
'>'    => \&dd_gt,
'>='   => \&dd_gte,
'<'    => \&dd_lt,
'<='   => \&dd_lte,
'*'    => \&dd_mul,
'*='   => \&dd_mul_eq,
'!='   => \&dd_neq,
'**'   => \&dd_pow,
'**='  => \&dd_pow_eq,
'<=>'  => \&dd_spaceship,
'""'   => \&dd_stringify,
'-'    => \&dd_sub,
'-='   => \&dd_sub_eq,
;

require Exporter;
*import = \&Exporter::import;

@Math::FakeDD::EXPORT_OK = qw(
  NV_IS_DOUBLE NV_IS_DOUBLEDOUBLE
  dd_abs dd_add dd_add_eq dd_assign dd_cmp dd_cos dd_dec dd_div dd_div_eq dd_eq dd_exp
  dd_gt dd_gte dd_int dd_log dd_lt dd_lte
  dd_mul dd_mul_eq dd_neq dd_pow dd_pow_eq dd_repro dd_sin dd_spaceship dd_sqrt dd_stringify
  dd_sub dd_sub_eq
);

%Math::FakeDD::EXPORT_TAGS = (all =>[@Math::FakeDD::EXPORT_OK]);

$Math::FakeDD::VERSION =  0.01;

Rmpfr_set_default_prec(2098);


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

  return mpfr2dd(shift);
}

sub dd_abs {
  my $obj;
  my $ret = Math::FakeDD->new();

  if(ref($_[0]) eq 'Math::FakeDD') {
    $obj = shift;
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

  $obj = Math::FakeDD->new(shift);
  my $mpfr = abs(dd2mpfr($obj)); # "abs" is "Math::MPFR::overload_abs"
  $obj = mpfr2dd($mpfr);
  $ret->{msd} = $obj->{msd};
  $ret->{lsd} = $obj->{lsd};
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
    $rop1 = Math::MPFR->new(shift);
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr(shift);
  }
  else {
    $rop2 = Math::MPFR->new(shift);
  }

  return mpfr2dd($rop1 + $rop2); # "+" is "Math::MPFR::overload_add"

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
    $rop2 = Math::MPFR->new($_[1]);
  }

  if(@_ > 2) {
    # dd_add_eq() has been called via
    # Math::FakeDD overloading of '+='.
    return mpfr2dd($rop1 + $rop2);          # "+" is "Math::MPFR::overload_add".
  }

  dd_assign($_[0], mpfr2dd($rop1 + $rop2)); # "+" is "Math::MPFR::overload_add".
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
    my $obj = mpfr2dd($val);
    $_[0]->{msd} = $obj->{msd};
    $_[0]->{lsd} = $obj->{lsd};
  }
}

sub dd_cmp {

  die "Wrong number of arguments given to dd_cmp()"
    unless @_ == 2;

  my ($rop1, $rop2);

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop1 = dd2mpfr(shift);
  }
  else {
#   $rop1 = Math::MPFR->new(shift);
    $rop1 = dd2mpfr(Math::FakeDD->new(shift));
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr(shift);
  }
  else {
#   $rop2 = Math::MPFR->new(shift);
    $rop2 = dd2mpfr(Math::FakeDD->new(shift));
  }

  return $rop1 <=> $rop2; # "<=>" is "Math::MPFR::overload_spaceship"
}

sub dd_cos {
  my $obj;
  if(ref($_[0]) eq 'Math::FakeDD') { $obj = shift }
  else {
    $obj = Math::FakeDD->new(shift);
  }
  my $ret = Math::FakeDD->new();
  my $mpfr = cos(dd2mpfr($obj)); # "cos" is "Math::MPFR::overload_cos"
  $obj = mpfr2dd($mpfr);
  $ret->{msd} = $obj->{msd};
  $ret->{lsd} = $obj->{lsd};
  return $ret;
}

sub dd_dec {
  die "Wrong arg given to dd_dec()"
    unless ref($_[0]) eq 'Math::FakeDD';
  return decimalize(dd2mpfr(shift));
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
    $rop1 = Math::MPFR->new(shift);
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr(shift);
  }
  else {
    $rop2 = Math::MPFR->new(shift);
  }

  if(@_ && $_[0]) { # switch args
    return mpfr2dd($rop2 / $rop1); # "/" is "Math::MPFR::overload_div"
  }
  return mpfr2dd($rop1 / $rop2);   # "/" is "Math::MPFR::overload_div"

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
    $rop2 = Math::MPFR->new($_[1]);
  }

  if(@_ > 2) {
    # dd_div_eq() has been called via
    # Math::FakeDD overloading of '/='.
    return mpfr2dd($rop1 / $rop2);          # "/" is "Math::MPFR::overload_div".
  }
  dd_assign($_[0], mpfr2dd($rop1 / $rop2)); # "/" is "Math::MPFR::overload_div"

}

sub dd_eq {

  # When dd_eq is called via overloading of '==' a
  # third argument (which we CAN ignore) will be provided
  die "Wrong number of args passed to dd_eq()"
    if(@_ > 3);
  return 0 if dd_cmp(shift, shift); # unequal
  return 1;                         # equal
}

sub dd_exp {
  my $obj;
  if(ref($_[0]) eq 'Math::FakeDD') { $obj = shift }
  else {
    $obj = Math::FakeDD->new(shift);
  }
  my $ret = Math::FakeDD->new();
  my $mpfr = exp(dd2mpfr($obj)); # "exp" is "Math::MPFR::overload_exp"
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
  my $mpfr = int(dd2mpfr($obj)); # "int" is "Math::MPFR::overload_int"
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
  my $mpfr = log(dd2mpfr($obj)); # "log" is "Math::MPFR::overload_log"
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
    $rop1 = Math::MPFR->new(shift);
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr(shift);
  }
  else {
    $rop2 = Math::MPFR->new(shift);
  }

  return mpfr2dd($rop1 * $rop2); # "*" is "Math::MPFR::overload_mul"

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
    $rop2 = Math::MPFR->new($_[1]);
  }

  if(@_ > 2) {
    # dd_mul_eq() has been called via
    # Math::FakeDD overloading of '*='.
    return mpfr2dd($rop1 * $rop2);          # "*" is "Math::MPFR::overload_mul".
  }

  dd_assign($_[0], mpfr2dd($rop1 * $rop2)); # "*" is "Math::MPFR::overload_mul".
}

sub dd_neq {

  # When dd_neq is called via overloading of '!=' a
  # third argument (which we CAN ignore) will be provided
  die "Wrong number of args passed to dd_neq()"
    if(@_ > 3);
  return 1 if dd_cmp(shift, shift); # unequal
  return 0;                         # equal
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
    $rop1 = Math::MPFR->new(shift);
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr(shift);
  }
  else {
    $rop2 = Math::MPFR->new(shift);
  }

  if(@_ && $_[0]) { # switch args
    return mpfr2dd($rop2 ** $rop1); # "**" is "Math::MPFR::overload_pow"
  }
  return mpfr2dd($rop1 ** $rop2);   # "**" is "Math::MPFR::overload_pow"

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
    $rop2 = Math::MPFR->new($_[1]);
  }

  if(@_ > 2) {
    # dd_pow_eq() has been called via
    # Math::FakeDD overloading of '**='.
    return mpfr2dd($rop1 ** $rop2);          # "**" is "Math::MPFR::overload_pow".
  }

  dd_assign($_[0], mpfr2dd($rop1 ** $rop2)); # "**" is "Math::MPFR::overload_pow".
}

sub dd_repro {
  die "Wrong arg given to dd_repro()"
    unless ref($_[0]) eq 'Math::FakeDD';
  return mpfrtoa(dd2mpfr(shift));
}

sub dd_sin {
  my $obj;
  if(ref($_[0]) eq 'Math::FakeDD') { $obj = shift }
  else {
    $obj = Math::FakeDD->new(shift);
  }
  my $ret = Math::FakeDD->new();
  my $mpfr = sin(dd2mpfr($obj)); # "sin" is "Math::MPFR::overload_sin"
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

  return $correction * dd_cmp(shift, shift);
}

sub dd_sqrt {
  my $obj;
  if(ref($_[0]) eq 'Math::FakeDD') { $obj = shift }
  else {
    $obj = Math::FakeDD->new(shift);
  }
  my $ret = Math::FakeDD->new();
  my $mpfr = sqrt(dd2mpfr($obj)); # "sqrt" is "Math::MPFR::overload_sqrt"
  $obj = mpfr2dd($mpfr);
  $ret->{msd} = $obj->{msd};
  $ret->{lsd} = $obj->{lsd};
  return $ret;
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
    $rop1 = Math::MPFR->new(shift);
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr(shift);
  }
  else {
    $rop2 = Math::MPFR->new(shift);
  }

  if(@_ && $_[0]) { # switch args
    return mpfr2dd($rop2 - $rop1); # "-" is "Math::MPFR::overload_sub"
  }
  return mpfr2dd($rop1 - $rop2);   # "-" is "Math::MPFR::overload_sub"

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
    $rop2 = Math::MPFR->new($_[1]);
  }

  if(@_ > 2) {
    # dd_sub_eq() has been called via
    # Math::FakeDD overloading of '-='.
    return mpfr2dd($rop1 - $rop2);          # "-" is "Math::MPFR::overload_sub".
  }
  dd_assign($_[0], mpfr2dd($rop1 - $rop2)); # "-" is "Math::MPFR::overload_sub"

}


sub dd2mpfr {
  my $self = shift;
  return Math::MPFR->new($self->{msd}) +
       + Math::MPFR->new($self->{lsd});
}

sub mpfr2dd {
  my %h;
  my $mpfr = Math::MPFR->new(shift);
  my $msd = Rmpfr_get_d($mpfr, MPFR_RNDN);
  if($msd == 0 || $msd != $msd || $msd / $msd != 1) { # $msd is zero, nan, or inf.
    $h{msd} = $msd;
    $h{lsd} = 0;
    return bless(\%h);
  }
  $mpfr -= $msd;
  my $lsd = Rmpfr_get_d($mpfr, MPFR_RNDN);
  $h{msd} = $msd;
  $h{lsd} = $lsd;
  return bless(\%h);
}

sub oload {
  # Return a list of the operator-function pairs for the overloaded
  # operators and the respective functions that they call.

  my %h = (
    'abs'  => 'dd_abs',
    'cos'  => 'dd_cos',
    'exp'  => 'dd_exp',
    'int'  => 'dd_int',
    'log'  => 'dd_log',
    'sin'  => 'dd_sin',
    'sqrt' => 'dd_sqrt',
    '+'    => 'dd_add',
    '+='   => 'dd_add_eq',
    '/'    => 'dd_div',
    '/='   => 'dd_div_eq',
    '=='   => 'dd_eq',
    '>'    => 'dd_gt',
    '>='   => 'dd_gte',
    '<'    => 'dd_lt',
    '<='   => 'dd_lte',
    '*'    => 'dd_mul',
    '*='   => 'dd_mul_eq',
    '!='   => 'dd_neq',
    '**'   => 'dd_pow',
    '**='  => 'dd_pow_eq',
    '<=>'  => 'dd_spaceship',
    '""'   => 'dd_stringify',
    '-'    => 'dd_sub',
    '-='   => 'dd_sub_eq'
);

  return %h
}

1;

