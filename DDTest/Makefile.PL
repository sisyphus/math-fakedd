use strict;
use warnings;
use ExtUtils::MakeMaker;

my %options = %{
{
  'NAME'     => 'Math::FakeDD::DDTest',
  'VERSION_FROM' => 'DDTest.pm',
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
# sub MY::makefile { '' }
