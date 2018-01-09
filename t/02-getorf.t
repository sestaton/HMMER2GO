use 5.010;
use strict;
use warnings FATAL => 'all';
use File::Spec;
use autodie             qw(open);
use IPC::System::Simple qw(system capture);

use Test::More tests => 19;

my $hmmer2go = File::Spec->catfile('blib', 'bin', 'hmmer2go');
my @menu     = capture([0..5], "$hmmer2go help getorf");

my ($opts, $orfs) = (0, 0);
my $infile        = File::Spec->catfile('t', 'test_data', 't_seqs_nt.fas');
my $infilegz      = File::Spec->catfile('t', 'test_data', 't_seqs_nt_gz.fas.gz');
my $infilebz      = File::Spec->catfile('t', 'test_data', 't_seqs_nt_bz.fas.bz2');
my $outfile_long  = File::Spec->catfile('t', 'test_data', 't_orfs_long.faa');
my $outfile_all   = File::Spec->catfile('t', 'test_data', 't_orfs_all.faa');
unlink $outfile_long if -e $outfile_long;
unlink $outfile_all  if -e $outfile_all;

for my $opt (@menu) {
    next if $opt =~ /^Err|^Usage|^hmmer2go|^ *$/;
    $opt =~ s/^\s+//;
    next unless $opt =~ /^-/;
    my ($option, $desc) = split /\s+/, $opt;
    ++$opts if $option;
}

is( $opts, 9, 'Correct number of options for hmmer2go getorf' );

for my $file ($infile, $infilegz, $infilebz) {
    unlink $outfile_long if defined $outfile_long && -e $outfile_long;
    ## Find longest ORF only
    my @result_long = capture([0..5], "$hmmer2go getorf -i $file -o $outfile_long -t 0");

    ok( -e $outfile_long, 'Successfully ran getorf and produced the expected output' );

    open my $longin, '<', $outfile_long;
    
    while (<$longin>) {
	++$orfs if /^>/;
    }
    close $longin;
    
    is( $orfs, 50, 'Expected number of ORFs found for test data when only keeping longest ORFs' );
    $orfs = 0;
    unlink $outfile_long;

    ## Find longest ORF only, choosing one if multiple exist at the same max length
    @result_long = capture([0..5], "$hmmer2go getorf -i $file -o $outfile_long -t 0 -c");

    ok( -e $outfile_long, 'Successfully ran getorf and produced the expected output' );

    open my $longinc, '<', $outfile_long;

    while (<$longinc>) {
        ++$orfs if /^>/;
    }
    close $longinc;

    is( $orfs, 50, 'Expected number of ORFs found for test data when only keeping longest ORFs' );
    $orfs = 0;
    
    ## Find all ORFs
    my @result_all = capture([0..5], "$hmmer2go getorf -i $file -o $outfile_all -t 0 -a");
 
    ok( -e $outfile_all, 'Successfully ran getorf and produced the expected output' );

    open my $allin, '<', $outfile_all;
    
    while (<$allin>) {
	++$orfs if /^>/;
    }
    close $allin;
    unlink $outfile_all;

    is( $orfs, 172, 'Expected number of ORFs found for test data when keeping all ORFs' );
    $orfs = 0;
}

done_testing();
