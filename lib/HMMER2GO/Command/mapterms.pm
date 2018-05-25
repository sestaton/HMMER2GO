package HMMER2GO::Command::mapterms;
# ABSTRACT: Map PFAM IDs from HMMscan search to GO terms.

use 5.010;
use strict; 
use warnings;
use HMMER2GO -command;
use IPC::System::Simple qw(system);
use Net::FTP;
use File::Basename;
use Carp;

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

    my $command = __FILE__;
    if ($self->app->global_options->{man}) {
	system([0..5], "perldoc $command");
    }
    else {
	$self->usage_error("Too few arguments.") 
	    unless $opt->{infile} && $opt->{outfile};
    }
} 

sub execute {
    my ($self, $opt, $args) = @_;

    exit(0) if $self->app->global_options->{man};
    my $infile   = $opt->{infile};
    my $pfam2go  = $opt->{pfam2go};
    my $outfile  = $opt->{outfile};
    my $map      = $opt->{map};
    my $keep     = 1;
    my $attempts = 3;

    if (!$pfam2go || ! -e $pfam2go) {
	$pfam2go = _retry($attempts, \&_fetch_mappings);
	$keep--;
    }

    my $result = _map_go_terms($infile, $pfam2go, $outfile, $map, $keep);
}

sub _map_go_terms {
    my ($infile, $pfam2go, $outfile, $map, $keep) = @_;

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
    while (my $line = <$in>) {
	chomp $line;
	next if $line =~ /^\#/;
	my ($target_name, $accession, $query_name, $accession_q, $E_value_full, 
	    $score_full, $bias_full, $E_value_best, $score_best, $bias_best, 
	    $exp, $reg, $clu, $ov, $env, $dom, $rev, $inc, @description_of_target) = split /\s+/, $line;
	my $description = join q{ }, @description_of_target;
	my $family = $accession;
	$family =~ s/\..*//;
	my $query_match_val = mk_key($family, $accession, $E_value_full, $description);

	push @{$pfamids{$query_name}}, $query_match_val;
    }
    close $in;

    my %goterms;
    my $go_ct = 0;
    my $map_ct = 0;

    while (my $mapping = <$pfams>) {
	chomp $mapping;
	next if $mapping =~ /^!/;
	if ($mapping =~ /Pfam:(\S+) (\S+ \> )(GO\:\S+.*\;) (GO\:\d+)/) {
	    my ($pf, $pf_name, $pf_desc, $go_term) = ($1, $2, $3, $4);
	    $pf_name =~ s/\s.*//;
	    $pf_desc =~ s/\s\;//;
	    for my $query_matches (keys %pfamids) {
		for my $query (@{$pfamids{$query_matches}}) {
		    my ($family, $accession, $E_value_full, $description) = mk_vec($query);
		    if ($family eq $pf) {
			say $out join "\t", $query_matches, $pf, $pf_name, $pf_desc, $go_term, $description;
			if ($mapping) {
			    if (exists $goterms{$query_matches}) {
				#$go_ct++ if defined($go_term);
				$goterms{$query_matches} .= ",".$go_term;
			    } 
                            else {
				$goterms{$query_matches} = $go_term;
			    }
			}
			last;
		    }
		}
	    }
	}
    }
    close $pfams;
    close $out;
    unlink $pfam2go unless $keep;

    if ($map) {
	for my $seqid (keys %goterms) {
	    $map_ct++;
	    my $termct = () = split /\,/, $goterms{$seqid}; #bugfix for #4
	    $go_ct += $termct;
	    say $map_fh join "\t", $seqid, $goterms{$seqid};
	}
	say "\n$map_ct query sequences with $go_ct GO terms mapped in file $mapfile.\n";
    }
}

sub _retry {
    my ($attempts, $func) = @_;
  attempt: {
      my $result;

      # if it works, return the result
      return $result if eval { $result = $func->(); 1 };

      # if we have 0 remaining attempts, stop trying.
      last attempt if $attempts < 1;

      # sleep for 1 second, and then try again.
      sleep 1;
      $attempts--;
      redo attempt;
  }

    croak "\nERROR: Failed to get mapping file after multiple attempts: $@";
}

sub _fetch_mappings {
    my $outfile = 'pfam2go';
    unlink $outfile if -e $outfile;
    
    my $host = "ftp.geneontology.org";
    my $dir  = "/pub/go/external2go";
    my $file = "pfam2go";

    my $ftp = Net::FTP->new($host, Passive => 1, Debug => 0)
	or warn "Cannot connect to $host: $@ will retry.";

    $ftp->login('anonymous', 'anonymous@foo.com')
	or warn "Cannot login ", $ftp->message, " will retry.";

    $ftp->cwd($dir)
        or warn "Cannot change working directory ", $ftp->message, " will retry.";

    my $rsize = $ftp->size($file) or warn "Could not get size ", $ftp->message, " will retry.";
    $ftp->get($file, $outfile) or warn "get failed ", $ftp->message, " will retry.";
    my $lsize = -s $outfile;

    $ftp->quit;

    warn "Failed to fetch complete file: $file (local size: $lsize, remote size: $rsize), will retry."
        unless $rsize == $lsize;

    return $outfile if $rsize == $lsize;
}

sub mk_key { join "~~", @_ }

sub mk_vec { split /\~\~/, shift }

1;
__END__

=pod

=head1 NAME 
                                                                       
 hmmer2go mapterms - Map Pfam IDs from HMMER search to GO terms from the Gene Ontology

=head1 SYNOPSIS    

 hmmer2go mapterms -i seqs_hmmscan.tblout -p pfam2go -o seqs_hmmscan_goterms.tsv --map 

=head1 DESCRIPTION
                                                                   
 This command takes the table output of HMMscan and maps go terms to your
 significant hits using the GO->PFAM mappings provided by the Gene Ontology
 (geneontology.org).

=head1 AUTHOR
 
S. Evan Staton, C<< <evan at evanstaton.com> >>

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

  GSVIVT01018890001PF00004AAA    GO:ATP binding    GO:0005524    ATPase
  GSVIVT01000580001PF00005ABC_tran    GO:ATP binding    GO:0005524    ABC
  GSVIVT01000580001PF00005ABC_tran    GO:ATPase activity    GO:0016887    ABC

=back

=head1 OPTIONS

=over 2

=item --map

Produce of tab-delimted file of query sequence IDs and GO terms. An example is below:

    sunf|NODE_1172150_length_184_cov_4_472826_5    GO:0004553,GO:0005975
    GSVIVT01027800001    GO:0016787
    sunf|NODE_1444993_length_180_cov_3_405555_4    GO:0004672,GO:0005524,GO:0006468
    saff|NODE_490685_length_227_cov_36_000000_9    GO:0005525,GO:0005634,GO:0005737

=item -h, --help

Print a usage statement. 

=item -m, --man

Print the full documentation.

=back

=cut 

