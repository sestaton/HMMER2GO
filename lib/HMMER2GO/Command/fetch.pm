package HMMER2GO::Command::fetch;
# ABSTRACT: Download the latest Pfam2GO mappings.

use 5.014;
use HMMER2GO -command;
use LWP::UserAgent;
use File::Basename;

sub opt_spec {
    return (    
	[ "outfile|o=s",  "A file to place the Pfam2GO mappings" ],
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;
       
    $self->usage_error("Too many arguments.") if @$args;
} 

sub execute {
    my ($self, $opt, $args) = @_;

    my $outfile = $opt->{outfile};

    my $result  = _fetch_mappings($outfile);
}

sub _fetch_mappings {
    my ($outfile) = @_;

    ## fetch pfam2go file http://www.geneontology.org/external2go/pfam2go
    $outfile //= 'pfam2go';

    my $ua = LWP::UserAgent->new;

    my $urlbase = 'http://www.geneontology.org/external2go/pfam2go ';
    my $response = $ua->get($urlbase);

    #
    # check for a response
    #
    unless ($response->is_success) {
	die "Can't get url $urlbase -- ", $response->status_line;
    }

    # 
    # open and parse the results
    #
    open my $out, '>', $outfile or die "\nERROR: Could not open file: $!\n";
    say $out $response->content;
    close $out;
}
1;
__END__

=pod

=head1 NAME
                                                                       
 hmmer2go fetch - Download the latest Pfam2GO mappings

=head1 SYNOPSIS    

 hmmer2go search -o pfam2go

=head1 DESCRIPTION
                                                                   

=head1 DEPENDENCIES


=head1 AUTHOR 

S. Evan Staton                                                

=head1 CONTACT
 
statonse at gmail dot com

=head1 REQUIRED ARGUMENTS

=over 2

=item -o, --outfile

A file to place the Pfam2GO mappings

=back

=head1 OPTIONS

=over 2

=item -h, --help

Print a usage statement. 

=item -m, --man

Print the full documentation.

=back

=cut
