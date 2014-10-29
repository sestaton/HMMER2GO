package HMMER2GO::Command::fetchmap;
# ABSTRACT: Download the latest Pfam2GO mappings.

use 5.010;
use strict;
use warnings;
use HMMER2GO -command;
use IPC::System::Simple qw(system);
use File::Basename;
use Net::FTP;

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
    my $outfile = $opt->{outfile};

    my $result  = _fetch_mappings($outfile);
}

sub _fetch_mappings {
    my ($outfile) = @_;

    $outfile //= 'pfam2go';

    my $host = "ftp.geneontology.org";
    my $dir  = "/pub/go/external2go";
    my $file = "pfam2go";

    my $ftp = Net::FTP->new($host, Passive => 1, Debug => 0)
    or die "Cannot connect to $host: $@";

    $ftp->login or die "Cannot login ", $ftp->message;

    $ftp->cwd($dir)
	or die "Cannot change working directory ", $ftp->message;

    my $rsize = $ftp->size($file) or die "Could not get size ", $ftp->message;
    $ftp->get($file, $outfile) or die "get failed ", $ftp->message;
    my $lsize = -s $outfile;

    die "Failed to fetch complete file: $file (local size: $lsize, remote size: $rsize)"
	unless $rsize == $lsize;
    
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

S. Evan Staton, C<< <statonse at gmail.com> >>

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
