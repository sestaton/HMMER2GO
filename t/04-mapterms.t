#!/usr/bin/env perl

use 5.012;
use strict;
use warnings FATAL => 'all';
use autodie qw(open);
use IPC::System::Simple qw(system capture);
use Test::More tests => 4;

my @menu = capture([0..5], "bin/hmmer2go help mapterms");

my ($opts, $orfs) = (0, 0);
my $infile  = "t/test_data/t_orfs_hmmscan-pfamA.tblout";
my $pfam2go = "t/test_data/pfam2go";
my $outfile = "t/test_data/t_hmmscan-pfamA_mapped_goterms.tsv";
my $mapfile = "t/test_data/t_hmmscan-pfamA_mapped_goterms_GOterm_mapping.tsv";

for my $opt (@menu) {
    next if $opt =~ /^Err|^Usage|^hmmer2go|^ *$/;
    $opt =~ s/^\s+//;
    next unless $opt =~ /^-/;
    my ($option, $desc) = split /\s+/, $opt;
    ++$opts if $option;
}

is($opts, 4, 'Correct number of options for hmmer2go mapterms');

my @result1 = capture([0..5], "bin/hmmer2go mapterms -i $infile -o $outfile -p $pfam2go");
ok(-e $outfile, 'Expected output from hmmer2go mapterms without mapping');
unlink $outfile;

my @result2 = capture([0..5], "bin/hmmer2go mapterms -i $infile -o $outfile -p $pfam2go --map");
ok(-e $outfile, 'Expected output from hmmer2go mapterms with mapping');
ok(-e $mapfile, 'Expected GO term mapping file produced with hmmer2go mapterms');
unlink $outfile;
unlink $mapfile;
unlink $pfam2go;

done_testing();
