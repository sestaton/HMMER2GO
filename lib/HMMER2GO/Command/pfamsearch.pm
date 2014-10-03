package HMMER2GO::Command::pfamsearch;
# ABSTRACT: Search terms against Pfam entries and create a custom HMM database.

use 5.010;
use strict;
use warnings;
use HMMER2GO -command;
use File::Basename;
use File::Path qw(make_path);
use LWP::UserAgent;
use XML::LibXML;
use HTML::TableExtract;

sub opt_spec {
    return (    
	[ "terms|t=s",   "The term(s) to search against Pfam entries"                ],
	[ "outfile|o=s", "The name of a file to write search results"                ],
	[ "createdb|d",  "A database of HMMs for the search terms should be created" ],
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

    my $result = _search_by_keyword($terms, $outfile, $createdb);
}

sub _search_by_keyword {
    my ($terms, $outfile, $createdb) = @_;

    my $keyword;
    ($keyword = $terms) =~ s/,/+/g;

    my $ua = LWP::UserAgent->new;
    my $urlbase  = "http://pfam.xfam.org/search/keyword?query=$keyword&submit=Submit";
    my $response = $ua->get($urlbase);

    unless ($response->is_success) {
	die "Can't get url $urlbase -- ", $response->status_line;
    }

    my $pfamxml = "pfam_search_$keyword".".xml";
    open my $pfout, '>', $pfamxml;
    say $pfout $response->content;
    close $pfout;

    my ($resultnum, $dbnum) = _get_search_results($keyword, $pfamxml);

    if ($resultnum > 1) {
	my $dirname = $keyword; # use expressive variable name

	if ($createdb) {
	    say "Found $resultnum HMMs for $keyword in $dbnum database(s).".
		" HMMs can be found in the directory: $dirname.";
	    make_path($dirname, {verbose => 0, mode => 0771,});
	}
	else {
	    say "Found $resultnum HMMs for $keyword in $dbnum database(s).";
	}

	open my $out, '>', $outfile;
	say $out "Accession\tID\tDescription";

	my $te = HTML::TableExtract->new( headers => [qw(Accession ID Description Seq_info)] );
	$te->parse_file($pfamxml);
	
	for my $ts ($te->tables) {
	    for my $row ($ts->rows) {
		my @elem = grep { defined } @$row;
		say $out join "\t", @elem[0..2];
		_fetch_hmm($dirname, \@elem, $createdb) if $createdb;
	    }
	}
	close $out;
    }
    unlink $pfamxml;
}
    
sub _get_search_results {
    my ($keyword, $pfamxml) = @_;
    my ($resultnum, $dbnum);

    $keyword =~ s/\+/ /g;
    open my $in, '<', $pfamxml;
    while (<$in>) {
	if (/We found \<strong\>(\d+)\<\/strong\> unique results/) {
	    $resultnum = $1;
	}
	if (/&quot\;\<em\>$keyword<\/em\>&quot\;\)\, in \<strong\>(\d+)\<\/strong\>/) {
	    $dbnum = $1;
	}
    }
    close $in;

    return $resultnum, $dbnum;
}

sub _fetch_hmm {
    my ($dir, $elem) = @_;

    my ($accession, $id, $descripton, $seqinfo) = @$elem;

    my $ua = LWP::UserAgent->new;
    my $urlbase  = "http://pfam.xfam.org/family/$accession/hmm";
    my $response = $ua->get($urlbase);

    unless ($response->is_success) {
        die "Can't get url $urlbase -- ", $response->status_line;
    }

    my $hmmfile = File::Spec->catfile($dir, $accession.".hmm");
    open my $hmmout, '>', $hmmfile;
    say $hmmout $response->content;
    close $hmmout;
}

1;
__END__

=pod

=head1 NAME
                                                                       
 hmmer2go pfamsearch

=head1 SYNOPSIS    

 hmmer2go pfamsearch

=head1 DESCRIPTION
  
=head1 DEPENDENCIES


=head1 AUTHOR 

S. Evan Staton, C<< <statonse at gmail.com> >>

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
