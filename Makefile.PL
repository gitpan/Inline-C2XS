use ExtUtils::MakeMaker;

print "*****************\nThis module is deprecated. Please install the latest version of InlineX::C2XS instead\n";
print "*****************\n";

my %options = %{
  {
  NAME     => 'Inline::C2XS',
  PREREQ_PM => {
                'Inline::C'  => 0.44,
               },
  VERSION_FROM => 'C2XS.pm',
  }
  };

WriteMakefile(%options);
