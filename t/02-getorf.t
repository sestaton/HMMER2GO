#!/usr/bin/env perl

use 5.012;
use strict;
use warnings FATAL => 'all';
use autodie qw(open);
use IPC::System::Simple qw(system capture);
use Test::More tests => 5;

my @menu = capture([0..5], "bin/hmmer2go help getorf");

my ($opts, $orfs) = (0, 0);
my $infile        = "t/test_data/t_seqs_nt.fas";
my $outfile_long  = "t/test_data/t_orfs_long.faa";
my $outfile_all   = "t/test_data/t_orfs_all.faa";
unlink $outfile_long if -e $outfile_long;
unlink $outfile_all  if -e $outfile_all;

for my $opt (@menu) {
    next if $opt =~ /^Err|^Usage|^hmmer2go|^ *$/;
    $opt =~ s/^\s+//;
    next unless $opt =~ /^-/;
    my ($option, $desc) = split /\s+/, $opt;
    ++$opts if $option;
}

is($opts, 8, 'Correct number of options for hmmer2go getorf');

## Find longest ORF only
my @result_long = capture([0..5], "bin/hmmer2go getorf -i $infile -o $outfile_long -t 0");

ok(-e $outfile_long, 'Successfully ran getorf and produced the expected output');

open my $longin, '<', $outfile_long;

while (<$longin>) {
    ++$orfs if /^>/;
}
close $longin;

is($orfs, 30, 'Expected number of ORFs found for test data when only keeping longest ORFs');
$orfs = 0;

## Find all ORFs
my @result_all = capture([0..5], "bin/hmmer2go getorf -i $infile -o $outfile_all -t 0 -a");

ok(-e $outfile_all, 'Successfully ran getorf and produced the expected output');

open my $allin, '<', $outfile_all;

while (<$allin>) {
    ++$orfs if /^>/;
}
close $allin;
unlink $outfile_all;

is($orfs, 52, 'Expected number of ORFs found for test data when keeping all ORFs');

done_testing();
