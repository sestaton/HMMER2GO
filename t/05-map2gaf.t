use 5.010;
use strict;
use warnings FATAL => 'all';
use File::Spec;
use autodie             qw(open);
use IPC::System::Simple qw(system capture);

use Test::More tests => 2;

my $hmmer2go = File::Spec->catfile('blib', 'bin', 'hmmer2go');
my @menu     = capture([0..5], "$hmmer2go help map2gaf");

my ($opts, $orfs) = (0, 0);
my $infile  = File::Spec->catfile('t', 'test_data', 't_long_Pfam-A_mapped_goterms_GOterm_mapping.tsv');
my $outfile = File::Spec->catfile('t', 'test_data', 't_long_Pfam-A_mapped_goterms_GOterm_mapping.gaf');
my $species = "Helianthus annuus";

for my $opt (@menu) {
    next if $opt =~ /^Err|^Usage|^hmmer2go|^ *$/;
    $opt =~ s/^\s+//;
    next unless $opt =~ /^-/;
    my ($option, $desc) = split /\s+/, $opt;
    ++$opts if $option;
}

is( $opts, 4, 'Correct number of options for hmmer2go map2gaf' );

my $devtests = 0;
if (defined $ENV{HMMER2GO_ENV} && $ENV{HMMER2GO_ENV} eq 'development') {
    $devtests = 1;
}

SKIP: {
    skip 'skip network tests', 1 unless $devtests;

    my @result1 = capture([0..5], "$hmmer2go map2gaf -i $infile -o $outfile -s $species");
    ok( -e $outfile, 'Expected output from hmmer2go map2gaf' );
    unlink $outfile;
}
unlink $infile;

done_testing();
