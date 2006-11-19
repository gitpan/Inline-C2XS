use ExtUtils::MakeMaker;

my %options = %{       
{
  NAME => 'MyMod',
  VERSION_FROM => 'MyMod.pm',
}
};

WriteMakefile(%options);