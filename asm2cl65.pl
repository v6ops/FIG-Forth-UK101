#!/usr/bin/perl
# convert original .asm 6502 assembler listing into cl65 format
# Unfortunately, there was never a real syntax standard for assembly
# beyond the definition of the mnemonic opcodes, so all assemblers
# invented their own. cl65 chosen as it was used in other projects.
# for loading into a "Grant Searle" style 6502.
# $1 is the input file (minus .ASM)
# output is to file $1.s which can be assembled by cl65
use strict;
use warnings;
my $fn = $ARGV[$#ARGV].".ASM";
my $fn2 = $ARGV[$#ARGV].".s";
open my $fh1, '<', $fn or die "can't open file $fn\n";
open my $fh2, '>', $fn2 or die "can't open file $fn2\n";
# output preamble for the ca65 assembler
#
print $fh2 ".segment \"ZERO\"\n";
my $done =0;
my $base=0x0400; # Where to load the code. 6502 is not relocatable. Re-assemble first!
my $o; # output
while (my $l=<$fh1>) {
  chomp $l;
  $l=~s/[\cM]+//g;# strip ctrl-M from input

  # Detect labels (in column 0) and translate to cl65
  # from
  # label    code 
  # to
  # label:
  #          code

  if ($l=~/(^[a-z,A-Z,0-9]+)(\s+)(.*)/) {
    my $a=$1; # remember the pattern match because we are rematching
    my $b=$2;
    my $c=$3;
    if ($c=~/^=/) {
      # this is actually setting a literal, so do nothing
      $o=$l;
     } else {
      my $s=length($a)+length($b); # remember how far to indent
      $o=$a.":"."\n";  # label:
      $o.=" " x $s;    # indent $s spaces
      $o.=$c;          # original code
    }
  } else {
    $o=$l; # do nothing on this line
  }

  # change string literals to double quotes
  if ($o=~/\s+\.BYTE\s+/) {
    $o=~s/\"/",\$22,"/g; # change existing double quotes to hex chars
    $o=~s/\'/\"/g;      # change single quotes to double quotes
  }

  # change the macro command
  #        .ORIGIN *+2
  #	  to NOP NOP
  #	  this is used to make sure no JMP addresses en in $FF
  #	  which was apparently an old hardware bug
  $o=~s/\s+\.ORIGIN\s+/ .res    2, \$EA; /; 
  # set our origin to $0400 hard coded
  # replaces *=*+2
  $o=~s/\s+\*=/.segment "CODE"\n.org \$0400 ; /; 


  print $fh2 $o."\n";
}
close $fh2;
close $fh1;
