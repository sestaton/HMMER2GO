use 5.010;
use strict;
use warnings FATAL => 'all';
use File::Spec;
use autodie             qw(open);
use IPC::System::Simple qw(system capture);

use Test::More tests => 9;

my $hmmer2go = File::Spec->catfile('blib', 'bin', 'hmmer2go');
my @menu     = capture([0..5], "$hmmer2go help mapterms");

my ($opts, $orfs) = (0, 0);
my $infile  = File::Spec->catfile('t', 'test_data', 't_orfs_long_Pfam-A.tblout');
my $pfam2go = File::Spec->catfile('t', 'test_data', 'pfam2go');
my $outfile = File::Spec->catfile('t', 'test_data', 't_long_Pfam-A_mapped_goterms.tsv');
my $mapfile = File::Spec->catfile('t', 'test_data', 't_long_Pfam-A_mapped_goterms_GOterm_mapping.tsv');

for my $opt (@menu) {
    next if $opt =~ /^Err|^Usage|^hmmer2go|^ *$/;
    $opt =~ s/^\s+//;
    next unless $opt =~ /^-/;
    my ($option, $desc) = split /\s+/, $opt;
    ++$opts if $option;
}

is( $opts, 4, 'Correct number of options for hmmer2go mapterms' );

my @result1 = capture([0..5], "$hmmer2go mapterms -i $infile -o $outfile -p $pfam2go");
ok( -e $outfile, 'Expected output from hmmer2go mapterms without mapping' );

my (%nonmapped, %mapped, %nomapfile);
open my $out1, '<', $outfile;
while (<$out1>) {
    chomp;
    my @f = split;
    $nonmapped{$f[0]}++;
}
close $out1;
unlink $outfile;
    
my @result2 = capture([0..5], "$hmmer2go mapterms -i $infile -o $outfile -p $pfam2go --map");
ok( -e $outfile, 'Expected output from hmmer2go mapterms with mapping' );
ok( -e $mapfile, 'Expected GO term mapping file produced with hmmer2go mapterms' );

open my $out2, '<', $outfile;
while (<$out2>) {
    chomp;
    my @f = split;
    $mapped{$f[0]}++;
}
close $out2;

is_deeply( \%nonmapped, \%mapped, 
	  'Same genes and GO term numbers returned with either mapping or not mapping option' );
unlink $outfile;

open my $map, '<', $mapfile;
while (<$map>) {
    chomp;
    my ($gene, $goterms) = split;
    my @terms = split /\,/, $goterms;
    if ($gene eq 'sunf_NODE_1382672_length_702_cov_5_594017_11_1') {
	is ( @terms, 6, 'Correct number of GO terms mapped' );
    }
    elsif ($gene eq 'sunf_NODE_626818_length_211_cov_6_417062_4_1') {
	is ( @terms, 2, 'Correct number of GO terms mapped' );
    }
    else {
	print "ERROR: Unexpected result: $gene:", scalar(@terms), ". This is a bug, please report it.\n";
    }
}
close $map;
unlink $pfam2go;

my @result3 = capture([0..5], "$hmmer2go mapterms -i $infile -o $outfile");
ok( -e $outfile, 'Expected output from hmmer2go mapterms without mapping file' );

open my $out3, '<', $outfile;
while (<$out3>) {
    chomp;
    my @f = split;
    $nomapfile{$f[0]}++;
}
close $out3;

is_deeply( \%mapped, \%nomapfile, 
	  'Same genes and GO term numbers returned with or without user-supplied mapping file' );
unlink $outfile;

done_testing();
