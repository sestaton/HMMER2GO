package Pfam2GO;

use Moo;
use LWP::UserAgent;
use namespace::clean;

## fetch pfam2go file http://www.geneontology.org/external2go/pfam2go
my $pfam2go = 'pfam2go';

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
# cpen and parse the results
#
open my $out, '>', $pfam2go or die "\nERROR: Could not open file: $!\n";
say $out $response->content;
close $out;

## then map terms

1;
