package HMMER2GO::Command::fetchmap;
# ABSTRACT: Download the latest Pfam2GO mappings.

use 5.010;
use strict;
use warnings;
use HMMER2GO -command;
use File::Basename;
use HTTP::Tiny;
use IPC::System::Simple qw(system);
use Carp;

our $VERSION = '0.18.3';

sub opt_spec {
    return (    
	[ "outfile|o=s",  "A file to place the Pfam2GO mappings" ],
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    my $command = __FILE__;
    if ($self->app->global_options->{man}) {
	system([0..5], "perldoc $command");
    }
    else {
	$self->usage_error("Too few arguments.") unless $opt->{outfile};
    }
} 

sub execute {
    my ($self, $opt, $args) = @_;

    exit(0) if $self->app->global_options->{man};
    my $outfile  = $opt->{outfile};
    my $attempts = 3;

    unless (_retry($attempts, \&_fetch_mappings, $outfile)) {
	$outfile = _fetch_mappings_curl($outfile);
	#unless (_fetch_mappings_curl($outfile)) {
	#my $success = _retry($attempts, \&_fetch_mappings, $outfile);
    }
}

sub _retry {
    my ($attempts, $func, $outfile) = @_;
    # this is modified from something by Kent Frederic
    # http://stackoverflow.com/a/1071877/1543853
  attempt : {
      my $result;

      # if it works, return the result
      return $result if eval { $result = $func->($outfile); 1 };

      # if we have 0 remaining attempts, stop trying.
      last attempt if $attempts < 1;

      # sleep for 1 second, and then try again.
      sleep 1;
      $attempts--;
      redo attempt;
  }

    warn "\n[WARNING]: Failed to get mapping file after multiple attempts: $@. Will retry one more time.";
    return 0;
}

sub _fetch_mappings {
    my ($outfile) = @_;

    $outfile //= 'pfam2go';

    my $urlbase  = 'http://current.geneontology.org/ontology/external2go/pfam2go';
    my $response = HTTP::Tiny->new->get($urlbase);

    unless ($response->{success}) {
	die "Can't get url $urlbase -- Status: ", $response->{status}, " -- Reason: ", $response->{reason};
    }

    open my $out, '>', $outfile or die "\nERROR: Could not open file: $outfile\n";
    say $out $response->{content};
    close $out;

    return $outfile;
}

sub _fetch_mappings_curl {
    my ($outfile) = @_;

    my $host = 'http://current.geneontology.org';
    my @dirs  = ('ontology', 'external2go');
    my $file = 'pfam2go';
    my $endpoint = join "/", $host, @dirs, $file;

    system([0..5], 'curl', '-u', 'anonymous:anonymous@foo.com', '-sL', '-o', $outfile, $endpoint) == 0
	or die "\n[ERROR]: 'wget' failed. Cannot fetch map file. Please report this error.";

    return $outfile;
}

1;
__END__

=pod

=head1 NAME
                                                                       
 hmmer2go fetchmap - Download the latest Pfam2GO mappings

=head1 SYNOPSIS    

 hmmer2go fetchmap -o pfam2go

=head1 DESCRIPTION
                                                                   
 The Gene Ontology frequently updates the Pfam to Gene Ontology term mappings,
 and it is a good idea to start with the most recent mapping file. This command
 will download the latest mappings, by default creating the file "pfam2go" or
 the user may specify a custom file name.

=head1 AUTHOR 

S. Evan Staton, C<< <evan at evanstaton.com> >>

=head1 REQUIRED ARGUMENTS

=over 2

=item -o, --outfile

A file to place the Pfam2GO mappings

=back

=head1 OPTIONS

=over 2

=item help

Print a usage statement. 

=item -m, --man

Print the full documentation.

=back

=cut
