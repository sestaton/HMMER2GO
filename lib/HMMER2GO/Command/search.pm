package HMMER2GO::Command::search;
# ABSTRACT: Run HMMscan on translated ORFs against Pfam database.

use 5.014;
use HMMER2GO -command;
use Cwd;
use IPC::System::Simple qw(capture system);
use File::Basename;

sub opt_spec {
    return (    
	[ "infile|i=s",    "The fasta file of translated amino acid sequences"     ],
	[ "cpus|n=i",      "The number of CPUs to use for the search"              ],
	[ "database|d=s", "The database to search against (typically Pfam-A.hmm)" ],
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;
       
    $self->usage_error("Too few arguments.") unless $opt->{infile} && $opt->{database};
} 

sub execute {
    my ($self, $opt, $args) = @_;

    my $infile   = $opt->{infile};
    my $database = $opt->{database};
    my $cpus     = $opt->{cpus};

    my $hmmscan = _find_prog("hmmscan");

    my $result = _run_hmmscan($hmmscan, $infile, $database, $cpus);
}

sub _run_hmmscan {
    my ($hmmscan, $infile, $database, $cpus) = @_;

    my ($iname, $ipath, $isuffix) = fileparse($infile, qr/\.[^.]*/);
    my $outfile   = $iname."_hmmscan-pfamA.out";
    my $domtblout = $iname."_hmmscan-pfamA.domtblout";
    my $tblout    = $iname."_hmmscan-pfamA.tblout";

    $cpus //= 1;

    if (-e $outfile) { 
	die "\nERROR: $outfile already exists. Exiting.\n";
    }
    
    my $hmmscan_cmd = "$hmmscan ".
	              "-o $outfile ".
		      "--tblout $tblout ".
		      "--domtblout $domtblout ".
		      "--acc ".
		      "--noali ".
		      "--cpu $cpus ".
		      "$database ".
		      "$infile";

    my $result = system([0..5], $hmmscan_cmd);
    return $result;
}

sub _find_prog {
    my $prog = shift;
    my $path = capture([0..5], "which $prog");
    chomp $path;
    
    if ($path !~ /$prog$/) {
	say 'Couldn\'t find hmmscan in PATH. Will keep looking.';
	$path = "/usr/local/hmmer/latest/bin/hmmscan";           # path at work
    }

    # Instead of just testing if hmmscan exists and is executable 
    # we want to make sure we have permissions, so we try to 
    # invoke hmmscan and examine the output. 
    my @hmmscan_out = capture([0..5], "$path -h");

    for (@hmmscan_out) {
	if (/^\# hmmscan/) { 
	    say "Using hmmscan located at: $path";
	    return $path;
	}
	elsif (/^-bash: \/usr\/local\/hmmer\/latest\/bin\/hmmscan\: No such file or directory$/) { 
	    die "Could not find hmmscan. Exiting.\n"; 
	}
	elsif ('') { 
	    die "Could not find hmmscan. Exiting.\n"; 
	}
	else { 
	    die "Could not find hmmscan. ".
		"Trying installing HMMER3 or adding it's location to your PATH. Exiting.\n"; 
	}
    }
    #return $path;
}

1;
__END__

=pod

=head1 NAME
                                                                       
 hmmer2go search - Run HMMscan on translated ORFs against Pfam database

=head1 SYNOPSIS    

 hmmer2go search -i seqs.fas -db Pfam-A.hmm -n 4

=head1 DESCRIPTION
                                                                   

=head1 DEPENDENCIES


=head1 AUTHOR 

S. Evan Staton                                                

=head1 CONTACT
 
statonse at gmail dot com

=head1 REQUIRED ARGUMENTS

=over 2

=item -i, --infile

The fasta file to be translated.

=back

=head1 OPTIONS

=over 2

=item -n, --cpus

 The number of CPUs to use for the HMMscan search.

=item -h, --help

Print a usage statement. 

=item -m, --man

Print the full documentation.

=back

=cut
