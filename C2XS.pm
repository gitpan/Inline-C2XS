package Inline::C2XS;
use warnings;
use strict;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(c2xs);

our $VERSION = 0.01;

sub c2xs {
    my $module = shift;
    my $package = shift;
    my $prelude = "#include \"EXTERN.h\"\n#include \"perl.h\"\n#include \"XSUB.h\"\n";
    my $postscript = "\n\nMODULE = $module\tPACKAGE = $package\n\nPROTOTYPES: DISABLE\n\n";

    my $filename = (split(/::/, $module))[-1];

    my $header_included = 0; # INLINE.h not included unless needed
    my $current = '';
    my $open_count = 0;
    my $close_count = 0;
    my $ignore = 0;
    my $script = '';
    my $done = 0;
    my @keep = ();
    my $backtrack = '';

    open(READ, "src/$filename.c") or die "Cannot open $filename.c for reading: $!";

    while(<READ>) {
     $script .= $_;
     if($ignore) { # Signifies that we're in the middle of a (multiline) comments section.
       if($_ =~ /\*\//) { # We've reached the end of the comments section
         $_ = $'; # Set $_ to what comes after the '*/'.
         $ignore = 0; # Signifies that we're not in a comments section
         if($_ eq "\n" || $_ eq '') {next} # $_ doesn't contain anything that can't be discarded.
         }
       else {next} # Still in the middle of multiline comments
       }
     if($_ =~ /^\s+\/\// || $_ =~ /^\/\//) {next} # Must be a line of comments only
     if($_ =~ /^\s+\/\*/ || $_ =~ /^\/\*/) { # Assumed to be comments only - not necessarily so.
       if($_ =~ /\*\//) {
         $_ = $';
         unless($_ =~ /\S/) {next}
         }
       else {
         $ignore = 1; # It's a multiline comment
         next;
         }
       }
     if($_ =~ /\/\//) {$_ = $`} # $_ = prematch
     if($_ =~ /\/\*/) {
       my $keep = $`;
       unless($_ =~ /\*\//) {$ignore = 1} # It's a multiline comment
       $_ = $keep; # $_ = prematch
       }
     if(!$header_included && ($_ =~ /inline_stack_vars/i)) { # Need to '#include "INLINE.h"' 
       $prelude .= "#include \"INLINE.h\"\n";
       write_inline_header(); # Create INLINE.h in the cwd
       $header_included = 1; # So that we know not to '#include "INLINE.h"' again
       }

     my $open_count_copy = $open_count; # Keeps a count of the {'s.
     my $close_count_copy = $close_count; # Keeps a count of the }'s.

     $open_count += $_ =~ tr/\{//;
     $close_count += $_ =~ tr/\}//;

     if(($open_count > $open_count_copy) && !$done) {
       @keep = split /\{/, $_;
       if($keep[0] =~ /\S/) {$current .= $keep[0] . "\n"}
       else {$current .= $backtrack}
       $done = 1;
       }

     if($close_count == $open_count) {$done = 0}
     if($_ =~ /\S/) {$backtrack = $_}
     }

     close(READ) or die "Cannot close $filename.c: $!";

     # $current is a list of prototypes
     $current =~ s/\n+/\n/g; # Remove unneeded newlines
     my $out = format_code($current);

     $prelude .= "\n";

     open(WRITE, ">$filename.xs") or die "Cannot open $filename.xs for writing: $!";
     print WRITE $prelude; # The additional includes
     print WRITE $script; # An exact copy of the original script
     print WRITE $postscript;
     print WRITE $out; # The xs listing
     close(WRITE) or die "Cannot close $filename.xs: $!";
}

sub format_code {
 my $ret = '';
 my $ellipsis = 0;
 my @start = split /\n/, $_[0];
 for(@start) {
    my $first = '';
    my @temp = ();
    my $second = '';
    my $last = '';
    my $in_brackets = '';
    my @proto = split /\(/, $_;
    chomp($proto[1]);
    $proto[1] =~ s/\)//;
    my @vars = split /,/, $proto[1];
    for(@vars) {
       $_ =~ s/^\s+//;
       if($_ !~ /\.\.\./) {$last .= "\t$_\n"}
       else {$ellipsis = 1}
       }
    if($last =~ /\S/) {$last = "\n" . $last} 
    for(@vars) {
       if($_ =~ /\*/) {$_ = $'}
       else {$_ = (split(/ /, $_))[-1]}
       }
    for(@vars) {
       $_ =~ s/\s//g;
       $_ = " " . $_;
       }
    $in_brackets = join(',', @vars);
    $in_brackets =~ s/^\s+//;
    $in_brackets =~ s/\s+$//;
    $in_brackets = '(' . $in_brackets . ')';
 
    if($proto[0] =~ /\*/) {
      $second = $';
      $first = $` . "*";
      }
    else {
      @temp = split / /, $proto[0];
      $second = pop(@temp);
      $first = join ' ', @temp;
      }

    $second =~ s/^\s+//;

    if($in_brackets eq '()') {$last = "\n"}

    if($first =~ /void/) {$last .= void_addon($second . " " . $in_brackets, $ellipsis)}

    $ret .= $first . "\n" . $second . " " . $in_brackets . $last . "\n";
    }

return $ret;
}

sub void_addon {
    my $func = shift;
    if($_[0]) {$func =~ s/, \.\.\.//g}
    return
"	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	$func;\n\tif (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */
";
}

sub write_inline_header {
open(WR, ">INLINE.h") or die "Cannot open INLINE.h for writing: $!";
print WR "
#define Inline_Stack_Vars	dXSARGS
#define Inline_Stack_Items      items
#define Inline_Stack_Item(x)	ST(x)
#define Inline_Stack_Reset      sp = mark
#define Inline_Stack_Push(x)	XPUSHs(x)
#define Inline_Stack_Done	PUTBACK
#define Inline_Stack_Return(x)	XSRETURN(x)
#define Inline_Stack_Void       XSRETURN(0)

#define INLINE_STACK_VARS	Inline_Stack_Vars
#define INLINE_STACK_ITEMS	Inline_Stack_Items
#define INLINE_STACK_ITEM(x)	Inline_Stack_Item(x)
#define INLINE_STACK_RESET	Inline_Stack_Reset
#define INLINE_STACK_PUSH(x)    Inline_Stack_Push(x)
#define INLINE_STACK_DONE	Inline_Stack_Done
#define INLINE_STACK_RETURN(x)	Inline_Stack_Return(x)
#define INLINE_STACK_VOID	Inline_Stack_Void

#define inline_stack_vars	Inline_Stack_Vars
#define inline_stack_items	Inline_Stack_Items
#define inline_stack_item(x)	Inline_Stack_Item(x)
#define inline_stack_reset	Inline_Stack_Reset
#define inline_stack_push(x)    Inline_Stack_Push(x)
#define inline_stack_done	Inline_Stack_Done
#define inline_stack_return(x)	Inline_Stack_Return(x)
#define inline_stack_void	Inline_Stack_Void
";
close(WR) or die "Cannot close INLINE.h after writing to it: $!";
}

1;

__END__

=head1 NAME

Inline::C2XS - create an XS file from an Inline C file.

=head1 DESCRIPTION

 Don't feed an actual Inline::C script to this module - it won't
 be able to parse it. It is capable of parsing correctly only
 that C code that is suitable for inclusion in an Inline::C
 script.

 For example, here is a simple Inline::C script:

  use warnings;
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

 Inline::C2XS looks for the file in ./src directory - expecting that the
 filename will be the same as what appears after the final '::' in the
 module name (with a '.c' extension). ie if the module is called
 My::Next::Mod it looks for a file ./src/Mod.c, and creates a file
 named Mod.xs (in the cwd). Also created in the cwd, is the file
 'INLINE.h' - but only if that file is needed.

 The created XS file, when packaged with the '.pm' file, an
 appropriate 'Makefile.PL', and 'INLINE.h' (if it's needed),
 can be used to build the module in the usual way - without
 any dependence upon the Inline C module.

=head1 SYNOPSIS

  use Inline::C2XS qw(c2xs);

  my $module_name = 'MY::XS_MOD';
  my $package_name = 'MY::XS_MOD';

  # Create XS_MOD.xs from ./src/XS_MOD.c. Also creates INLINE.h, if
  # that file is needed. 'XS_MOD.c' must be in a format that works
  # with the Inline::C module and must be in the ./src folder.
  c2xs($module_name, $package_name);

=head1 BUGS

  Assumes that the function prototypes/declarations are written on 
  the one line - ie a .c file containing this works fine:

  unsigned long some_func(int a, double b, SV * c)
    {
    // code
    }

  And this also works fine:

  unsigned long some_func(int a, double b, SV * c) {
    // code
    }

  But this won't work (though it's valid C code, and works with
  Inline::C):

  unsigned long some_func(int a,
                          double b,
                          SV * c)
    {
    // code
    }

  Also, safest to keep comments to separate lines, or to the end of a
  line. This won't be correctly parsed (by either Inline::C or Inline::C2XS):

  /* A comment */ void another_func(char * something) // Another comment
     {
     printf("%s\n", something);
     }

  But there's no problem with:

  /* A comment */
  void another_func(char * something) { // Another comment
     printf("%s\n", something);
     }

  And there's no problem with:

  void another_func(char * something) { /* A comment
  continuation of comment */ 
     printf("%s\n", something);
     }

  Same applies to single line comments (//). 

  Probably other bugs, too - patches/rewrites welcome.
  Send to sisyphus at cpan dot org

=head1 COPYRIGHT

  Copyright Sisyphus. You can do whatever you want with this code.
  It comes without any guarantee or warranty.

=cut

