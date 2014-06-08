#!/usr/bin/env perl

use 5.012;
use strict;
use warnings FATAL => 'all';
use IPC::System::Simple qw(system capture);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use LWP::UserAgent;
use File::Copy qw(move);
use Test::More tests => 4;

my @menu = capture([0..5], "bin/hmmer2go help search");

my ($opts, $orfs) = (0, 0);
my $infile    = "t/test_data/t_orfs.faa";
my $outfile   = "t_orfs_hmmscan-pfamA.out";
my $domtblout = "t_orfs_hmmscan-pfamA.domtblout";
my $tblout    = "t_orfs_hmmscan-pfamA.tblout";

my $db = _fetch_db();

for my $opt (@menu) {
    next if $opt =~ /^Err|^Usage|^hmmer2go|^ *$/;
    $opt =~ s/^\s+//;
    next unless $opt =~ /^-/;
    my ($option, $desc) = split /\s+/, $opt;
    ++$opts if $option;
}

is($opts, 3, 'Correct number of options for hmmer2go search');

my @result = capture([0..5], "bin/hmmer2go search -i $infile -d $db");
ok(-e $outfile,   'Expected raw output of HMMscan from hmmer2go search');
ok(-e $domtblout, 'Expected domain table output of HMMscan from hmmer2go search');
ok(-e $tblout,    'Expected hit table output of HMMscan from hmmer2go search');

unlink $outfile;
unlink $domtblout;
move $tblout, "t/test_data/$tblout";

done_testing();

# methods
sub _fetch_db {
    my $url      = 'ftp://ftp.ebi.ac.uk/pub/databases/Pfam/current_release';
    my $file     = 'Pfam-A.hmm.gz';
    my $endpoint = $url."/$file";
    my $outfile  = 't/test_data/Pfam-A.hmm.gz';
    my $flatdb   = 't/test_data/Pfam-A.hmm';

    diag("Fetching database for testing. This could take a few minutes...");
 
    #my $ua = LWP::UserAgent->new;

    #my $response = $ua->get($endpoint);

    #unless ($response->is_success) {
    #    die "Can't get url $endpoint -- ", $response->status_line;
    #}

    #open my $out, '>', $outfile or die "\nERROR: Could not open file: $!\n";
    #say $out $response->content;
    #close $out;

    diag("Done fetching database. Uncompressing database for testing...");

    #my $status = gunzip $outfile => $flatdb
    #    or die "gunzip failed: $GunzipError\n";

    #unlink $outfile;

    diag("Done uncompressing database. Running hmmpress on database. This will take a few minutes...");
    #my $db = _run_hmmpress($flatdb);

    diag("Done running hmmpress on database. Now testing hmmer2go search.");
    return $flatdb;
}

sub _run_hmmpress {
    my ($flatdb) = @_;

    # TODO: test if we can use hmmpress for testing
    my @result = capture([0..5], "hmmpress $flatdb");

    return $flatdb;
}
    
