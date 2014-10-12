#!/usr/bin/env perl

use 5.010;
use strict;
use warnings FATAL => 'all';
use autodie qw(open);
use IPC::System::Simple qw(system capture);
use File::Path qw(remove_tree);
use File::Spec;
use Test::More tests => 5;

my $term      = "mads,mads-box";
my $ntfile    = "t/test_data/t_seqs_nt.fas";
my $infile    = "t/test_data/t_orfs_long.faa";
my $outfile   = "t_orfs_long_mads+mads-box.out";
my $domtblout = "t_orfs_long_mads+mads-box.domtblout";
my $tblout    = "t_orfs_long_mads+mads-box.tblout";

my ($outdir, $db) = ($term, $term);
$outdir =~ s/,/+/g;
$db =~ s/,/+/g;
$outdir .= "_hmms";
my $customdb = File::Spec->catfile($outdir, $db.".hmm");

my @result_long = capture([0..5], "bin/hmmer2go getorf -i $ntfile -o $infile -t 0");
ok( -e $infile, 'Successfully ran getorf and produced the expected output' );

my @db_result = capture([0..5], "bin/hmmer2go pfamsearch -t $term -o $outfile -d");
ok( -e $customdb, 'Expected HMM database created' );
unlink $outfile;

my @run_result = capture([0..5], "bin/hmmer2go run -i $infile -d $customdb" );
ok( -e $outfile,   'Expected raw output of HMMscan from hmmer2go search' );
ok( -e $domtblout, 'Expected domain table output of HMMscan from hmmer2go search' );
ok( -e $tblout,    'Expected hit table output of HMMscan from hmmer2go search' );

unlink $infile;
unlink $outfile;
unlink $domtblout;
unlink $tblout;
remove_tree($outdir);
