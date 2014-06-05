package Getorf::Command::getorf;

use Getorf -command;

sub usage_desc { "getorf_app_cmd.pl %o [somefile ...]" }

sub opt_spec {
    return (    
	[ "infile|i=s",    "The fasta files to be translated"                     ],
	[ "outfile|o=s",   "A file to place the translated sequences"             ],
	[ "orflen|l=i",    "The minimum length for which to report an ORF"        ],
	[ "translate|t", "Determines what to report for each ORF"                 ],
	[ "sameframe|s", "Report all ORFs in the same (sense) frame"              ],
	[ "nomet|nm",    "Do not report only those ORFs starting with Methionine" ],
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;
       
    $self->usage_error("Too few arguments.") unless @$args;
} 

sub execute {
    my ($self, $opt, $args) = @_;

    print "Everything has been initialized. (Not really)\n";
}

=pod

=head1 NAME
                                                                       
getorf - Run EMBOSS getorf and extract longest reading frames.

=cut

1;
