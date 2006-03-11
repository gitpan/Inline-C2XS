use ExtUtils::MakeMaker;

my %options = %{
{
  NAME     => 'Inline::C2XS',
  VERSION_FROM => 'C2XS.pm',
}
};

WriteMakefile(%options);
