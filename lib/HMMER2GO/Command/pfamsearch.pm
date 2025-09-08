package HMMER2GO::Command::pfamsearch;
# ABSTRACT: Search terms against Pfam entries and create a custom HMM database.

use 5.010;
use strict;
use warnings;
use HMMER2GO -command;
use File::Spec;
use File::Basename;
use File::Find;
use File::Path          qw(make_path);
use IPC::System::Simple qw(system capture);
use HTTP::Tiny;
use Try::Tiny;
use XML::LibXML;
use HTML::TableExtract;
use JSON::Tiny qw(decode_json);

our $VERSION = '0.19.0';

sub opt_spec {
    return (    
	[ "terms|t=s",   "The term(s) to search against Pfam entries"                                        ],
	[ "outfile|o=s", "The name of a file to write search results"                                        ],
	[ "createdb|d",  "A database of HMMs for the search terms should be created"                         ],
	[ "dirname|n=s", "The name of the directory to create for storing HMMs from the Pfam search results" ],
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
	    unless $opt->{terms} && $opt->{outfile};
    }
} 

sub execute {
    my ($self, $opt, $args) = @_;


    exit(0) if $self->app->global_options->{man};
    my $terms     = $opt->{terms};
    my $outfile   = $opt->{outfile};
    my $createdb  = $opt->{createdb};
    my $dirname   = $opt->{dirname};


    if ($createdb && $dirname && -d $dirname) {
	say "\n[ERROR]: $dirname exists so it will not be overwritten. ".
	    "Please specify a different directory name. Exiting.\n";
	exit(1);
    }

    my $result = _search_by_keyword($terms, $outfile, $createdb, $dirname);
}

sub _search_by_keyword {
    my ($terms, $outfile, $createdb, $dirname) = @_;

    my ($keyword, $dbname);
    ($keyword = $terms) =~ s/\s+|,/+/g;

    # Use EBI Search API to find InterPro entries, then extract Pfam entries
    my $ebi_search_url = "https://www.ebi.ac.uk/ebisearch/ws/rest/interpro?query=$keyword&format=json&size=200";
    my $response = HTTP::Tiny->new->get($ebi_search_url);

    unless ($response->{success}) {
        die "Can't get url $ebi_search_url -- Status: ", $response->{status}, " -- Reason: ", $response->{reason};
    }

    my $search_results = _parse_ebi_search_results($response->{content});
    my $pfam_entries = _get_pfam_entries_from_interpro($search_results);

    my $resultnum = scalar @$pfam_entries;
    my $dbnum = 1; # All results come from InterPro now

    if ($resultnum > 0) {
        say "Found $resultnum HMMs for $keyword in $dbnum database(s)." if !$createdb;
	$dbname = $keyword."_hmms" if !$dirname; # use expressive variable name
	$dbname = $dirname if $dirname;
	if (-d $dbname) {
	    say "\n[ERROR]: $dbname exists. Please choose a directory name for the database ".
		"so that no data is destroyed. Exiting.\n";
	    exit(1);
	}

	if ($createdb) {
	    say "Found $resultnum HMMs for $keyword in $dbnum database(s).".
		" HMMs can be found in the directory: $dbname.";
	    make_path($dbname, {verbose => 0, mode => 0771,});
	}
	else {
	    say "Found $resultnum HMMs for $keyword in $dbnum database(s).";
	}

	open my $out, '>', $outfile or die "\n[ERROR]: Could not open file: $outfile\n";
	say $out "Accession\tID\tDescription";

	for my $entry (@$pfam_entries) {
	    say $out join "\t", @$entry;
	    if ($createdb) {
		my @elem = @$entry;
		_fetch_hmm($dbname, \@elem, $createdb);
	    }
	}
	close $out;
    }
    else {
	say "No Pfam entries found for search term: $keyword";
	# Create empty output file
	open my $out, '>', $outfile or die "\n[ERROR]: Could not open file: $outfile\n";
	say $out "Accession\tID\tDescription";
	close $out;
	return;
    }

    _run_hmmpress($dbname, $keyword) if $createdb;
}

sub _parse_ebi_search_results {
    my ($json_content) = @_;
    
    my $data = decode_json($json_content);
    my @entry_ids = ();
    
    if ($data->{entries} && ref $data->{entries} eq 'ARRAY') {
        for my $entry (@{$data->{entries}}) {
            push @entry_ids, $entry->{id} if $entry->{id};
        }
    }
    
    return \@entry_ids;
}

sub _get_pfam_entries_from_interpro {
    my ($interpro_ids) = @_;
    
    my @pfam_entries = ();
    
    for my $interpro_id (@$interpro_ids) {
        # Get InterPro entry details to find associated Pfam entries
        my $interpro_url = "https://www.ebi.ac.uk/interpro/api/entry/interpro/$interpro_id/";
        my $response = HTTP::Tiny->new->get($interpro_url);
        
        if ($response->{success}) {
            eval {
                my $data = decode_json($response->{content});
                
                # Extract Pfam entries from member_databases
                if ($data->{metadata} && $data->{metadata}->{member_databases} && $data->{metadata}->{member_databases}->{pfam}) {
                    my $pfam_entries_ref = $data->{metadata}->{member_databases}->{pfam};
                    
                    for my $pfam_acc (keys %$pfam_entries_ref) {
                        my $pfam_desc = $pfam_entries_ref->{$pfam_acc};
                        push @pfam_entries, [$pfam_acc, $pfam_acc, $pfam_desc];
                    }
                }
            };
            if ($@) {
                warn "Warning: Could not parse InterPro entry $interpro_id: $@\n";
            }
        }
    }
    
    return \@pfam_entries;
}
    
sub _get_search_results {
    my ($keyword, $pfamxml) = @_;
    my ($resultnum, $dbnum);

    $keyword =~ s/\+/ /g;
    open my $in, '<', $pfamxml or die "\n[ERROR]: Could not open file: $pfamxml\n";
    while (my $line = <$in>) {
	chomp $line;
	if ($line =~ /We found \<strong\>(\d+)\<\/strong\> unique results/) {
	    $resultnum = $1;
	}
	if ($line =~ /\&quot\;\<em\>$keyword\<\/em\>\&quot\; in \<strong\>(\d+)\<\/strong\>/) {
	    $dbnum = $1;
	}
    }
    close $in;

    return $resultnum, $dbnum;
}

sub _fetch_hmm {
    my ($dbname, $elem, $createdb) = @_;
    
    return unless $createdb;

    my ($accession, $id, $descripton) = @$elem;

    # Try the new InterPro API first, fall back to old URL if needed
    my @urls = (
        "https://www.ebi.ac.uk/interpro/api/entry/pfam/$accession/?format=hmm",
        "https://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.gz",
        "http://pfam.xfam.org/family/$accession/hmm"
    );
    
    for my $urlbase (@urls) {
        my $response = HTTP::Tiny->new->get($urlbase);
        
        if ($response->{success} && $response->{content}) {
            my $content = $response->{content};
            
            # If it's the full database, extract just this entry
            if ($urlbase =~ /Pfam-A\.hmm\.gz$/) {
                # This would require gunzip and parsing - skip for now
                next;
            }
            
            # Check if we got HMM content
            if ($content =~ /^HMMER3/m) {
                my $hmmfile = File::Spec->catfile($dbname, $accession.".hmm");
                open my $hmmout, '>', $hmmfile or die "\n[ERROR]: Could not open file: $hmmfile\n";
                say $hmmout $content;
                close $hmmout;
                return;
            }
        }
    }
    
    warn "Warning: Could not fetch HMM file for $accession\n";
}

sub _run_hmmpress {
    my ($dbname, $keyword) = @_;

    my $hmmpress = _find_prog('hmmpress');
    my $hmmdb    = File::Spec->catfile($dbname, $keyword.".hmm");
    my @hmmfiles;

    find( sub {
	push @hmmfiles, $File::Find::name if -f and /\.hmm$/i;
	  }, $dbname);

    open my $hmmout, '>>', $hmmdb or die "\n[ERROR]: Could not open file: $hmmdb\n";

    for my $file (@hmmfiles) {
	open my $in, '<', $file or die "\n[ERROR]: Could not open file: $file\n";
	print $hmmout $_ while <$in>;
	close $in;
    }

    my @hmm_res;
    try {
	@hmm_res = capture([0..5], $hmmpress, $hmmdb);
    }
    catch {
	die "\n[ERROR]: hmmpress exited. Here is the exception: $_\n";
    };

    return $hmmdb;
}

sub _find_prog {
    my ($prog) = @_;
    my @path = split /:|;/, $ENV{PATH};

    my $exepath;

    for my $p (@path) {
        my $exe = File::Spec->catfile($p, $prog);
        
	if (-e $exe) {
	    $exepath = $exe;
	    last;
	}
    }

    if (-e $exepath && -x $exepath) {
	return $exepath;
    }
    else { 
	die "\n[ERROR]: Could not find $prog. Trying installing HMMER3 or adding it's location to your PATH. Exiting.\n"; 
    }
}

1;
__END__

=pod

=head1 NAME
                                                                       
 hmmer2go pfamsearch - Search terms against Pfam entries and create a custom HMM database

=head1 SYNOPSIS    

 hmmer2go pfamsearch -t mads -o mads_pfam_results.txt -d

=head1 DESCRIPTION

 This command will allow one to search Pfam with simple terms like 'transposable element'
 or 'mads' and optionally create a database of HMMs for each result matching those terms.  

=head1 AUTHOR 

S. Evan Staton, C<< <evan at evanstaton.com> >>

=head1 REQUIRED ARGUMENTS

=over 2

=item -i, --infile

The fasta file to be translated.

=item -o, --outfile

The file to write the results to, which will be a tab-delimited file with tree columns
in the format:

    Pfam-accession Pfam-ID Description

=back

=head1 OPTIONS

=over 2

=item -d, --createdb

With this option, a database will be created consisting of all the Pfams matching the search terms.
A separate directory will created from the search terms and the HMMs for each Pfam will be placed
in that directory (unless a directory name is given).

=item -n, -dirname

A name for database. This will be the name of a directory containing the HMMs from the search results.

=item -h, --help

Print a usage statement. 

=item -m, --man

Print the full documentation.

=back

=cut
