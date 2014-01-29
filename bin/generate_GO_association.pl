#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use File::Basename;
use Getopt::Long;
#use Data::Dumper;

my $infile;
my $outfile;
my $GOfile;
my $species;

GetOptions(
	   'i|infile=s'  => \$infile,
	   'o|outfile=s' => \$outfile,
	   'g|gofile=s'  => \$GOfile,
	   's|species=s' => \$species,
	   );

if (!$infile  || !$outfile || 
    !$species || !$GOfile) {
    usage();
    exit(1);
}

open my $in, '<', $infile or die "\nERROR: Could not open file: $infile\n";
open my $go, '<', $GOfile or die "\nERROR: Could not open file: $GOfile\n";
open my $out, '>', $outfile or die "\nERROR: Could not open file: $outfile\n";

say $out "!gaf-version: 2.0";

my %gohash;
while (<$go>) {
    chomp;
    next if /^!/;
    my @go_data = split;
    next if $go_data[-1] eq "obs";
    $gohash{$go_data[0]} = $go_data[-1];
}
close $go;

while (<$in>) {
    chomp;
    my @go_mappings = split /\t/, $_;
    my $dbstring = "db.".$go_mappings[0];
    my @go_terms = split /\,/, $go_mappings[1];
    for my $term (@go_terms) {
	if (exists $gohash{$term}) {
	    say $out join "\t", $species,$dbstring,$go_mappings[0],"0",$term,"PMID:0000000",
                    "ISO","0",$gohash{$term},"0","0","gene","taxon:79327","23022011","PFAM";
	}
    }
}
close $in;
close $out;

exit;
#
#
#
sub usage {
    my $script = basename($0);
    print STDERR <<END

USAGE: $script -i gene_go_mapping -o gaf -s some_species -g GO_file [-h]

Required:
    -i|infile        :    Tab-delimited file containing gene => GO term mappings (GO terms
                          should be separated by commas).
    -o|outfile       :    File name for the association file.
    -s|species       :    The species name to be used in the association file.
    -g|gofile        :    GO_alt_ids file containing the one letter code for each term.

Options:
    -h|help          :    Print a usage statement.

END
}
