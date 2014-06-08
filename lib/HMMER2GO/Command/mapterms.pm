package HMMER2GO::Command::mapterms;
# ABSTRACT: Map PFAM IDs from HMMscan search to GO terms.

use 5.014;
use HMMER2GO -command;
use utf8;
use charnames qw(:full :short);
use strict; 
use warnings;
use warnings FATAL => "utf8";
use Getopt::Long;
use Pod::Usage;
use File::Basename;

# given/when emits warnings in v5.18+
no if $] >= 5.018, 'warnings', "experimental::smartmatch";

sub opt_spec {
    return (    
        [ "infile|i=s",  "The HMMscan output in table format (generated with '--tblout' option from HMMscan)."  ],
        [ "outfile|o=s",  "The file to hold the GO term/description mapping results."                           ],
        [ "pfam2go|p=s", "The PFAMID->GO mapping file provided by the Gene Ontology. "                          ],
        [ "map",         "Produce of tab-delimted file of query sequence IDs and GO terms."                     ],
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;
       
    $self->usage_error("Too few arguments.") unless $opt->{infile} && $opt->{outfile} && $opt->{pfam2go};
} 

sub execute {
    my ($self, $opt, $args) = @_;

    my $infile  = $opt->{infile};
    my $pfam2go = $opt->{pfam2go};
    my $outfile = $opt->{outfile};
    my $map     = $opt->{map};

    my $result = _map_go_terms($infile, $pfam2go, $outfile, $map);
}

sub _map_go_terms {
    my ($infile, $pfam2go, $outfile, $map) = @_;

    ## create filehandles, if possible
    open my $in, '<', $infile or die "\nERROR: Could not open file: $infile\n";
    open my $pfams, '<', $pfam2go or die "\nERROR: Could not open file: $pfam2go\n";
    open my $out, '>', $outfile or die "\nERROR: Could not open file: $outfile\n";

    my ($mapfile, $map_fh);
    if ($map) {
	$mapfile = $outfile;
	$mapfile =~ s/\..*//g;
	$mapfile .= "_GOterm_mapping.tsv";
	open $map_fh, '>', $mapfile or die "\nERROR: Could not open file: $mapfile\n";
    }

    my %pfamids;
    while (<$in>) {
	chomp;
	next if /^\#/;
	my ($target_name, $accession, $query_name, $accession_q, $E_value_full, 
	    $score_full, $bias_full, $E_value_best, $score_best, $bias_best, 
	    $exp, $reg, $clu, $ov, $env, $dom, $rev, $inc, $description_of_target) = split;
	my $query_eval = mk_key($query_name, $E_value_full, $description_of_target);
	$accession =~ s/\..*//;
	$pfamids{$query_eval} = $accession;
    }
    close $in;

    my %goterms;
    my $go_ct = 0;
    my $map_ct = 0;

    while (my $mapping = <$pfams>) {
	chomp $mapping;
	next if $mapping =~ /^!/;
	if ($mapping =~ /Pfam:(\S+) (\S+ \> )(GO\:\S+.*\;) (GO\:\d+)/) {
	    my $pf = $1;
	    my $pf_name = $2;
	    my $pf_desc = $3;
	    my $go_term = $4;
	    $pf_name =~ s/\s.*//;
	    $pf_desc =~ s/\s\;//;
	    for my $key (keys %pfamids) { ##TODO: As below, be more expressive
		my ($query, $e_val, $desc) = mk_vec($key);
		if ($pfamids{$key} eq $pf) {
		    say $out join "\t", $query, $pf, $pf_name, $pf_desc, $go_term, $desc;
		    if ($mapping) {
			if (exists $goterms{$query}) {
			    $go_ct++ if defined($go_term);
			    $goterms{$query} .= ",".$go_term;
			} else {
			    $goterms{$query} = $go_term;
			}
		    }
		    last;
		}
	    }
	}
    }
    close $pfams;
    close $out;

    if ($map) {
	while (my ($key, $value) = each %goterms) { ##TODO: Be more expressive than key/value
	    $map_ct++;
	    say $map_fh join "\t", $key, $value;
	}
	say "\n$map_ct query sequences with $go_ct GO terms mapped in file $mapfile.\n";
    }
}

sub mk_key { join "\N{INVISIBLE SEPARATOR}", @_ }

sub mk_vec { split "\N{INVISIBLE SEPARATOR}", shift }

1;
__END__

=pod

=head1 NAME 
                                                                       
 hmmer2go mapterms - Map PFAM IDs from HMMscan search to GO terms 

=head1 SYNOPSIS    

 hmmer2go mapterms -i seqs_hmmscan.tblout -p pfam2go -o seqs_hmmscan_goterms.tsv --map 

=head1 DESCRIPTION
                                                                   
 This script takes the table output of HMMscan and maps go terms to your
 significant hits using the GO->PFAM mappings provided by the Gene Ontology
 (geneontology.org).

=head1 TESTED WITH:

=over

=item *
Perl 5.14.1 (Red Hat Enterprise Linux Server release 5.7 (Tikanga))

=head1 AUTHOR
 
statonse at gmail dot com

=head1 REQUIRED ARGUMENTS

=over 2

=item -i, --infile

The HMMscan output in table format (generated with "--tblout" option from HMMscan).

=item -p, --pfam2go

The PFAMID->GO mapping file provided by the Gene Ontology. 
Direct link: http://www.geneontology.org/external2go/pfam2go

=item -o, --outfile

The file to hold the GO term/description mapping results. The format is tab-delimited
and contains: QueryID, PFAM_ID, PFAM_Name, PFAM_Description, GO_Term, GO_Description. An example
from grape is below: 

  GSVIVT01018890001PF00004AAAGO:ATP bindingGO:0005524ATPase
  GSVIVT01000580001PF00005ABC_tranGO:ATP bindingGO:0005524ABC
  GSVIVT01000580001PF00005ABC_tranGO:ATPase activityGO:0016887ABC

=back

=head1 OPTIONS

=over 2

=item --map

Produce of tab-delimted file of query sequence IDs and GO terms. An example is below:

    sunf|NODE_1172150_length_184_cov_4_472826_5GO:0004553,GO:0005975
    GSVIVT01027800001GO:0016787
    sunf|NODE_1444993_length_180_cov_3_405555_4GO:0004672,GO:0005524,GO:0006468
    saff|NODE_490685_length_227_cov_36_000000_9GO:0005525,GO:0005634,GO:0005737

=item -h, --help

Print a usage statement. 

=item -m, --man

Print the full documentation.

=cut 

