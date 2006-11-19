package MyMod;
use warnings;
use strict;

require Exporter;
require DynaLoader;

our $VERSION = 0.01;

our @ISA = qw(Exporter DynaLoader);

our @EXPORT_OK = qw(erf);

bootstrap MyMod $VERSION;

1;
