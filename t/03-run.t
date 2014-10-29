#!/usr/bin/env perl

use 5.010;
use strict;
use warnings FATAL => 'all';
use IPC::System::Simple qw(system capture);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use Net::FTP;
use File::Copy qw(move);
use File::Spec;
use Test::More tests => 4;

my @menu = capture([0..5], "bin/hmmer2go help run");

my $opts      = 0;
my $full_test = 0;
my $infile    = "t/test_data/t_orfs_long.faa";
my $outfile   = "t_orfs_long_Pfam-A.out";
my $domtblout = "t_orfs_long_Pfam-A.domtblout";
my $tblout    = "t_orfs_long_Pfam-A.tblout";

for my $opt (@menu) {
    next if $opt =~ /^Err|^Usage|^hmmer2go|^ *$/;
    $opt =~ s/^\s+//;
    next unless $opt =~ /^-/;
    my ($option, $desc) = split /\s+/, $opt;
    ++$opts if $option;
}

is($opts, 4, 'Correct number of options for hmmer2go run');

SKIP: {
    skip 'skip lengthy tests', 3 unless $full_test; 
    my $db = _fetch_db();

    my @result = capture([0..5], "bin/hmmer2go run -i $infile -d $db");
    my $out = File::Spec->catfile('t', 'test_data', $outfile);
    my $dom = File::Spec->catfile('t', 'test_data', $domtblout);
    my $tbl = File::Spec->catfile('t', 'test_data', $tblout);

    move $outfile,   $out or die "move failed: $!";
    move $domtblout, $dom or die "move failed: $!";
    move $tblout,    $tbl or die "move failed: $!";

    ok(-e $out, 'Expected raw output of HMMscan from hmmer2go search');
    ok(-e $dom, 'Expected domain table output of HMMscan from hmmer2go search');
    ok(-e $tbl, 'Expected hit table output of HMMscan from hmmer2go search');

    unlink $out;
    unlink $dom;
};

unlink $infile; 
done_testing();

# methods
sub _fetch_db {
    my $host    = "ftp.ebi.ac.uk";
    my $dir     = "/pub/databases/Pfam/current_release";
    my $file    = "Pfam-A.hmm.gz";
    my $outfile = "t/test_data/Pfam-A.hmm.gz";
    my $flatdb  = "t/test_data/Pfam-A.hmm";

    my $ftp = Net::FTP->new($host, Passive => 1, Debug => 0)
    or die "Cannot connect to $host: $@";

    $ftp->login or die "Cannot login ", $ftp->message;

    $ftp->cwd($dir)
        or die "Cannot change working directory ", $ftp->message;

    diag("Fetching database for testing. This could take a few minutes...");
    
    $ftp->binary();
    my $rsize = $ftp->size($file) or die "Could not get size ", $ftp->message;
    $ftp->get($file, $outfile) or die "get failed ", $ftp->message;
    #sleep 10;
    my $lsize = -s $outfile;

    die "Failed to fetch complete file: $file (local size: $lsize, remote size: $rsize)"
        unless $rsize == $lsize;

    diag("Done fetching database. Uncompressing database for testing...");

    my $status = gunzip $outfile => $flatdb
        or die "gunzip failed: $GunzipError\n";

    unlink $outfile;

    diag("Done uncompressing database. Running hmmpress on database. This will take a few minutes...");
    my $db = _run_hmmpress($flatdb);

    diag("Done running hmmpress on database. Now testing hmmer2go search.");
    return $flatdb;
}

sub _run_hmmpress {
    my ($flatdb) = @_;

    # TODO: test if we can use hmmpress for testing
    my @result = capture([0..5], "hmmpress $flatdb");

    return $flatdb;
}
    
