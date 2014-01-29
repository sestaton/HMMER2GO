#!/usr/bin/env perl 

use 5.010;
use strict; 
use warnings;
use Getopt::Long;
use Data::Dumper;

my $usage = "\n$0 -i annot -o outfile\n";
my $infile;
my $outfile;

GetOptions(
           'i|infile=s'  => \$infile,
           'o|outfile=s' => \$outfile,
           );

if (!$infile) {
    die "\nERROR: no infile found.\n",$usage;
}

if (!$outfile) {
    die "\nERROR: No outfile found.\n",$usage;
}

open my $in, '<', $infile or die "\nERROR: Could not open file: $infile\n";
open my $out, '>', $outfile or die "\nERROR: Could not open file: $outfile\n";

while (<$in>) {
    chomp;
    my @f = split /\t/;
    say join "\t", $out $f[4], "ND", $f[0];
}

close $in;
close $out;
