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

our $VERSION = '0.18.1';

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

    my $urlbase  = "http://pfam.xfam.org/search/keyword?query=$keyword"; #&submit=Submit";
    my $response = HTTP::Tiny->new->get($urlbase);

    unless ($response->{success}) {
        die "Can't get url $urlbase -- Status: ", $response->{status}, " -- Reason: ", $response->{reason};
    }

    my $pfamxml = "pfam_search_$keyword.xml";
    open my $pfout, '>', $pfamxml or die "\n[ERROR]: Could not open file: $pfamxml\n";
    say $pfout $response->{content};
    close $pfout;

    my ($resultnum, $dbnum) = _get_search_results($keyword, $pfamxml);

    if (defined $resultnum && $resultnum > 1) {
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

	my $te = HTML::TableExtract->new( headers => [ qw(Accession ID Description Seq_info)] );
	$te->parse_file($pfamxml);
	
	for my $ts ($te->tables) {
	    for my $row ($ts->rows) {
		my @elem = grep { defined } @$row;
		say $out join "\t", @elem[0..2];
		_fetch_hmm($dbname, \@elem, $createdb) if $createdb;
	    }
	}
	close $out;
    }
    unlink $pfamxml;

    _run_hmmpress($dbname, $keyword) if $createdb;
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
    my ($dbname, $elem) = @_;

    my ($accession, $id, $descripton, $seqinfo) = @$elem;

    my $urlbase  = "http://pfam.xfam.org/family/$accession/hmm";
    my $response = HTTP::Tiny->new->get($urlbase);

    unless ($response->{success}) {
        die "Can't get url $urlbase -- Status: ", $response->{status}, " -- Reason: ", $response->{reason};
    }

    my $hmmfile = File::Spec->catfile($dbname, $accession.".hmm");
    open my $hmmout, '>', $hmmfile or die "\n[ERROR]: Could not open file: $hmmfile\n";
    say $hmmout $response->{content};
    close $hmmout;
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
