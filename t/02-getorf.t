#!/usr/bin/env perl

use 5.012;
use strict;
use warnings FATAL => 'all';
use autodie qw(open);
use IPC::System::Simple qw(system capture);
use Test::More tests => 3;

my @menu = capture([0..5], "bin/hmmer2go help getorf");

my ($opts, $orfs) = (0, 0);
my $infile  = "t/test_data/t_seqs_nt.fas";
my $outfile = "t/test_data/t_orfs.faa";

for my $opt (@menu) {
    next if $opt =~ /^Err|^Usage|^hmmer2go|^ *$/;
    $opt =~ s/^\s+//;
    next unless $opt =~ /^-/;
    my ($option, $desc) = split /\s+/, $opt;
    ++$opts if $option;
}

is($opts, 7, 'Correct number of options for hmmer2go getorf');

my @result = capture([0..5], "bin/hmmer2go getorf -i $infile -o $outfile -t 0");

ok(-e $outfile, 'Successfully ran getorf and produced the expected output');

open my $in, '<', $outfile;

while (<$in>) {
    ++$orfs if /^>/;
}
close $in;

is($orfs, 30, 'Expected number of ORFs found for test data');

done_testing();
