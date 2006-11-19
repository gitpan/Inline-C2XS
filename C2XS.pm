package Inline::C2XS;
use warnings;
use strict;
use Carp;
use Config;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(c2xs);

our $VERSION = 0.07;

sub c2xs {
    eval {require "Inline/C.pm"};
    if($@ || $Inline::C::VERSION < 0.44) {die "Need a functioning Inline::C (version 0.44 or later). $@"}
    my $module = shift;
    my $pkg = shift;
    my $build_dir = shift || '.';
    my $config_options = shift ||
       {
       'AUTOWRAP' => 0,
       'AUTO_INCLUDE' => '',
       'TYPEMAPS' => [],
       'INC' => '',
       };
    unless(-d $build_dir) {
       warn "$build_dir is not a valid directory ... file(s) will be written to the cwd instead\n";
       $build_dir = '.';
    }
    my $modfname = (split /::/, $module)[-1];
    my $need_inline_h = $config_options->{AUTOWRAP} ? 1 : 0;
    my $code = '';
    my $o;

    open(RD, "<", "src/$modfname.c") or die "Can't open src/${modfname}.c for reading: $!";
    while(<RD>) { 
         $code .= $_;
         if($_ =~ /inline_stack_vars/i) {$need_inline_h = 1}
    }
    close(RD) or die "Can't close src/$modfname.c after reading: $!";

    ## Initialise $o.
    ## Many of these keys may not be needed for the purpose of this
    ## specific exercise - but they shouldn't do any harm, so I'll
    ## leave them in, just in case they're ever needed.
    $o->{CONFIG}{BUILD_TIMERS} = 0;
    $o->{CONFIG}{PRINT_INFO} = 0;
    $o->{CONFIG}{USING} = [];
    $o->{CONFIG}{WARNINGS} = 1;
    $o->{CONFIG}{PRINT_VERSION} = 0;
    $o->{CONFIG}{CLEAN_BUILD_AREA} = 0;
    $o->{CONFIG}{GLOBAL_LOAD} = 0;
    $o->{CONFIG}{DIRECTORY} = '';
    $o->{CONFIG}{SAFEMODE} = -1;
    $o->{CONFIG}{CLEAN_AFTER_BUILD} = 1;
    $o->{CONFIG}{FORCE_BUILD} = 0;
    $o->{CONFIG}{NAME} = '';
    $o->{CONFIG}{_INSTALL_} = 0;
    $o->{CONFIG}{WITH} = [];
    $o->{CONFIG}{AUTONAME} = 1;
    $o->{CONFIG}{REPORTBUG} = 0;
    $o->{CONFIG}{UNTAINT} = 0;
    $o->{CONFIG}{VERSION} = '';
    $o->{CONFIG}{BUILD_NOISY} = 1;
    $o->{INLINE}{ILSM_suffix} = $Config::Config{dlext};
    $o->{INLINE}{ILSM_module} = 'Inline::C';
    $o->{INLINE}{version} = $Inline::VERSION;
    $o->{INLINE}{ILSM_type} = 'compiled';
    $o->{INLINE}{DIRECTORY} = 'irrelevant_0';
    $o->{INLINE}{object_ready} = 0;
    $o->{INLINE}{md5} = 'irrelevant_1';
    $o->{API}{modfname} = $modfname;
    $o->{API}{script} = 'irrelevant_2';
    $o->{API}{location} = 'irrelevant_3';
    $o->{API}{language} = 'C';
    $o->{API}{modpname} = 'irrelevant_4';
    $o->{API}{directory} = 'irrelevant_5';
    $o->{API}{install_lib} = 'irrelevant_6';
    $o->{API}{build_dir} = $build_dir;
    $o->{API}{language_id} = 'C';
    $o->{API}{pkg} = $pkg;
    $o->{API}{suffix} = $Config::Config{dlext};
    $o->{API}{cleanup} = 1;
    $o->{API}{module} = $module;
    $o->{API}{code} = $code;

    if($config_options->{AUTOWRAP}) {$o->{ILSM}{AUTOWRAP} = 1}

    if(scalar(@{$config_options->{TYPEMAPS}})) {
      push @{$o->{ILSM}{MAKEFILE}{TYPEMAPS}}, @{$config_options->{TYPEMAPS}}; 
    }

    if($config_options->{INC}) {$o->{ILSM}{MAKEFILE}{INC} .= " $config_options->{INC}"}

    bless($o, 'Inline::C');

    Inline::C::validate($o);
    if(!$need_inline_h) {$o->{ILSM}{AUTO_INCLUDE} =~ s/#include "INLINE.h"//i}
    if($config_options->{AUTO_INCLUDE}) {$o->{ILSM}{AUTO_INCLUDE} .= $config_options->{AUTO_INCLUDE} . "\n"} 

    _build($o, $need_inline_h);
}

sub _build {
    my $o = shift;
    my $need_inline_headers = shift;
    
    $o->call('preprocess', 'Build Preprocess');
    $o->call('parse', 'Build Parse');

    print "Writing ", $o->{API}{modfname}, ".xs in the ", $o->{API}{build_dir}, " directory\n";
    $o->call('write_XS', 'Build Glue 1');

    if($need_inline_headers) {
      print "Writing INLINE.h in the ", $o->{API}{build_dir}, " directory\n";
      $o->call('write_Inline_headers', 'Build Glue 2');
    }
}
1;

__END__

=head1 NAME

Inline::C2XS - create an XS file from Inline C code.

=head1 SYNOPSIS

  use Inline::C2XS qw(c2xs);

  my $module_name = 'MY::XS_MOD';
  my $package_name = 'MY::XS_MOD';

  # $build_dir is an optional third arg
  my $build_dir = '/some/where/else';

  # $config_opts is an optional fourth arg (hash reference)
  my $config_opts = {'AUTOWRAP' => 1,
                     'AUTO_INCLUDE' => 'my_header.h',
                     'TYPEMAPS' => ['my_typemap'],
                     'INC' => '-Imy/includes/dir',
                    };

  # Create /some/where/else/XS_MOD.xs from ./src/XS_MOD.c
  c2xs($module_name, $package_name, $build_dir);

  # Or create XS_MOD.xs in the cwd:
  c2xs($module_name, $package_name);

  The optional fourth arg (a reference to a hash) is to enable the
  writing of XS files using Inline::C's autowrap capability. 
  It currently only accommodates 4 hash keys - AUTOWRAP, INC, 
  AUTO_INCLUDE, and TYPEMAPS - though other keys may be added in
  in the future to accommodate additional functionality.

  # Create XS_MOD.xs in the cwd, using the AUTOWRAP feature:
  c2xs($module_name, $package_name, '.', $config_opts);

=head1 DESCRIPTION
 
 Don't feed an actual Inline::C script to this module - it won't
 be able to parse it. It is capable of parsing correctly only
 that C code that is suitable for inclusion in an Inline::C
 script.

 For example, here is a simple Inline::C script:

  use warnings;
  use Inline C => Config =>
      BUILD_NOISY => 1,
      CLEAN_AFTER_BUILD => 0;
  use Inline C => <<'EOC';
  #include <stdio.h>

  void greet() {
      printf("Hello world\n");
  }
  EOC

  greet();
  __END__

 The C file that Inline::C2XS needs to find would contain only that code
 that's between the opening 'EOC' and the closing 'EOC' - namely:

  #include <stdio.h>

  void greet() {
      printf("Hello world\n");
  }

 Inline::C2XS looks for the source file in ./src directory - expecting
 that the filename will be the same as what appears after the final '::'
 in the module name (with a '.c' extension). ie if your module is
 called My::Next::Mod the c2xs() function looks for a file ./src/Mod.c, 
 and creates a file named Mod.xs. Also created by the c2xs function, is
 the file 'INLINE.h' - but only if that file is needed. The generated 
 xs file (and INLINE.h) will be written to the cwd unless a third 
 argument (specifying a valid directory) is provided to the c2xs
 function.

 The created XS file, when packaged with the '.pm' file, an
 appropriate 'Makefile.PL', and 'INLINE.h' (if it's needed), can be 
 used to build the module in the usual way - without any dependence
 upon the Inline::C module.

=head1 BUGS

  None known - patches/rewrites/enhancements welcome.
  Send to sisyphus at cpan dot org

=head1 COPYRIGHT

  Copyright Sisyphus. You can do whatever you want with this code.
  It comes without any guarantee or warranty.

=cut

