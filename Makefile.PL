use ExtUtils::MakeMaker;

@prereq = ('Inline::C' => 0.44);

my %options = %{
{
  NAME     => 'Inline::C2XS',
  PREREQ_PM => {@prereq},
  VERSION_FROM => 'C2XS.pm',
}
};

WriteMakefile(%options);
