use 5.010;
use strict;
use warnings FATAL => 'all';
use autodie             qw(open);
use IPC::System::Simple qw(system capture);
use File::Path          qw(remove_tree);
use File::Spec;

use Test::More tests => 10;

my $hmmer2go = File::Spec->catfile('blib', 'bin', 'hmmer2go');
my @menu     = capture([0..5], "$hmmer2go help pfamsearch");

my $opts    = 0;
my $term    = "mads,mads-box";
my $outfile = File::Spec->catfile('t', 'hmmer2go_test_termsearch.out');

for my $opt (@menu) {
    next if $opt =~ /^Err|^Usage|^hmmer2go|^ *$/;
    $opt =~ s/^\s+//;
    next unless $opt =~ /^-/;
    my ($option, $desc) = split /\s+/, $opt;
    ++$opts if $option;
}

is( $opts, 4, 'Correct number of options for hmmer2go pfamsearch' );

my ($hmmnum, $dbnum, $outdir);
($outdir = $term) =~ s/,/+/g;
$outdir .= "_hmms";
my @result = capture([0..5], "$hmmer2go pfamsearch -t $term -o $outfile");

for my $res (@result) {
    if ($res =~ /Found (\d+) HMMs for \S+ in (\d+)/) {
	($hmmnum, $dbnum) = ($1, $2);
    }
}

is( $hmmnum, 13, 'Found the correct number of HMMs for the search term' );
is( $dbnum,  4, 'Found the HMMs in the correct number of databases' );

ok( -s $outfile, 'Output file of descriptions produced' );

my (@hmmres, @db_hmmres);
open my $in, '<', $outfile;
@hmmres = <$in>;
close $in;
unlink $outfile;

# +1 for the header
is( $hmmnum, @hmmres - 1, 'Wrote the correct number of descriptions to the output file' );

my @db_result = capture([0..5], "$hmmer2go pfamsearch -t $term -o $outfile -d");

for my $dbres (@db_result) {
    like( $dbres, qr/HMMs can be found in the directory/, 
	  'The output directory information is presented when creating a database' );
}

my @db_hmms = glob("$outdir/PF*");
is( $hmmnum, scalar @db_hmms, 'Fetched the correct number of HMMs for the search term' );

my @alldb_hmms = glob("$outdir/*.hmm");
is( $hmmnum+1, scalar @alldb_hmms, 'Created the correct number of HMMs for the search term' );

open my $dbin, '<', $outfile;
@db_hmmres = <$dbin>;
close $dbin;

is_deeply( \@hmmres, \@db_hmmres, 'Same output file generated when creating a database vs. not' );
unlink $outfile;

my @hmmp_files = glob("$outdir/*.h3*");
is( scalar @hmmp_files, 4, 'Correct number of files create by hmmpress' );
remove_tree($outdir);
