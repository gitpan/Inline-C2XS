use warnings;
use strict;
use Inline::C2XS qw(c2xs);

print "1..2\n";

c2xs('Some::Package::test_c2xs', 'MyPackage');

if(!rename('test_c2xs.xs', 'test_c2xs.txt')) {
  print "not ok 1 - couldn't rename test_c2xs.xs\n";
  exit;
}

my $ok = 1;

if(!open(RD1, "test_c2xs.txt")) {
  print "not ok 1 - unable to open test_c2xs.txt for reading: $!\n";
  exit;
}

if(!open(RD2, "expected.txt")) {
  print "not ok 1 - unable to open expected.txt for reading: $!\n";
  exit;
}

my @rd1 = <RD1>;
my @rd2 = <RD2>;

if(scalar(@rd1) != scalar(@rd2)) {
  print "not ok 1 - test_c2xs.txt does not have the expected number of lines\n";
  close(RD1) or print "Unable to close test_c2xs.txt after reading: $!\n";
  close(RD2) or print "Unable to close expected.txt after reading: $!\n";
  exit;
}

for(my $i = 0; $i < scalar(@rd1); $i++) {
   # Try to take care of platform-specific issues with line endings.
   $rd1[$i] =~ s/\n//g;
   $rd2[$i] =~ s/\n//g;
   $rd1[$i] =~ s/\r//g;
   $rd2[$i] =~ s/\r//g;

   if($rd1[$i] ne $rd2[$i]) {
     print $i, "\n", $rd1[$i], "*\n", $rd2[$i], "*\n";
     $ok = 0;
     last;
   }
}

if(!$ok) {
  print "not ok 1 - test_c2xs.txt does not match expected.txt\n";
  close(RD1) or print "Unable to close test_c2xs.txt after reading: $!\n";
  close(RD2) or print "Unable to close expected.txt after reading: $!\n";
  exit;
}

print "ok 1\n";

close(RD1) or print "Unable to close test_c2xs.txt after reading: $!\n";
close(RD2) or print "Unable to close expected.txt after reading: $!\n";
if(!unlink('test_c2xs.txt')) { print "Couldn't unlink test_c2xs.txt\n"}

$ok = 1;

###########################################################################

if(!open(RD1, "INLINE.h")) {
  print "not ok 2 - unable to open INLINE.h for reading: $!\n";
  exit;
}

if(!open(RD2, "expected.h")) {
  print "not ok 2 - unable to open expected.h for reading: $!\n";
  exit;
}

@rd1 = <RD1>;
@rd2 = <RD2>;

if(scalar(@rd1) != scalar(@rd2)) {
  print "not ok 2 - INLINE.h does not have the expected number of lines\n";
  close(RD1) or print "Unable to close INLINE.h after reading: $!\n";
  close(RD2) or print "Unable to close expected.h after reading: $!\n";
  exit;
}

for(my $i = 0; $i < scalar(@rd1); $i++) {
   # Try to take care of platform-specific issues with line endings.
   $rd1[$i] =~ s/\n//g;
   $rd2[$i] =~ s/\n//g;
   $rd1[$i] =~ s/\r//g;
   $rd2[$i] =~ s/\r//g;

   if($rd1[$i] ne $rd2[$i]) {
     $ok = 0;
     last;
   }
}

if(!$ok) {
  print "not ok 2 - INLINE.h does not match expected.h\n";
  close(RD1) or print "Unable to close INLINE.h after reading: $!\n";
  close(RD2) or print "Unable to close expected.h after reading: $!\n";
  exit;
}

close(RD1) or print "Unable to close INLINE.h after reading: $!\n";
close(RD2) or print "Unable to close expected.h after reading: $!\n";
if(!unlink('INLINE.h')) { print "Couldn't unlink INLINE.h\n"}

print "ok 2\n";
