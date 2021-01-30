package HMMER2GO::Command::fetchmap;
# ABSTRACT: Download the latest Pfam2GO mappings.

use 5.010;
use strict;
use warnings;
use HMMER2GO -command;
use File::Basename;
use Net::FTP;
use IPC::System::Simple qw(system);
use Carp;

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

    my $host = 'ftp.geneontology.org';
    my $dir  = '/pub/go/external2go';
    my $file = 'pfam2go';

    my $ftp = Net::FTP->new($host, Passive => 1, Debug => 0)
	or warn "Cannot connect to $host: $@, will retry.";

    $ftp->login('anonymous', 'anonymous@foo.com') 
	or warn "Cannot login ", $ftp->message, " will retry.";

    $ftp->cwd($dir)
	or warn "Cannot change working directory ", $ftp->message, " will retry.";

    my $rsize = $ftp->size($file) 
	or warn "Could not get size ", $ftp->message, " will retry.";
    $ftp->get($file, $outfile) 
	or warn "get failed ", $ftp->message, " will retry.";
    my $lsize = -s $outfile;

    $ftp->quit;

    if (defined $lsize && $lsize == $rsize) {
	return 1;
    }
    else {
	$lsize //= 0;
	warn "\n[WARNING]: Failed to fetch complete file: $file (local size: $lsize, remote size: $rsize), will retry.";
	return 0;
    }    
}

sub _fetch_mappings_curl {
    my ($outfile) = @_;

    my $host = 'ftp://ftp.geneontology.org';
    my $dir  = 'pub/go/external2go';
    my $file = 'pfam2go';
    my $endpoint = join "/", $host, $dir, $file;

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
