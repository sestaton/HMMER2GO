package HMMER2GO::Run::Getorf;

use 5.012;
use Moo;
use Cwd;
use Capture::Tiny qw(:all);
use File::Basename;
use File::Temp;
use namespace::autoclean;

# guide to ebi webservices: http://www.ebi.ac.uk/Tools/webservices/services/pfa/hmmer_hmmscan_rest

=head1 NAME

HMMER - Run HMMER3 and store results in table format for mapping GO terms

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    my $hmmer = HMMER2GO::Run::HMMER->new(   );

=cut

#
# Vars
#
my $infile; 
my $outfile;
my $orflen;
my $sense;
my $find;
my $nomet;
my $help;
my $man;

#
# Counters
#
my $fcount = 0;
my $orfseqstot = 0;

GetOptions(#Required
	      'i|infile=s'     => \$infile,
	      'o|outfile=s'    => \$outfile,
	      #Options
	      'l|orflen=i'     => \$orflen,
	      't|translate'    => \$find,
	      's|sameframe'    => \$sense,
	      'nm|nomet'       => \$nomet,
	      'h|help'         => \$help,
	      'm|man'          => \$man,
    );

pod2usage( -verbose => 2 ) if $man;

#
# Check @ARGVs
#  
usage() and exit(0) if $help;

if (!$infile || !$outfile) {
    say "\nERROR: No input was given.\n";
    usage();
    exit(1);
}

# Set default values.
$find //= '0';
$orflen //= '80';

my $getorf = find_prog("getorf");  ## use build

if (-e $outfile) { 
# Because we are appending the ORFs from each sequence to the same output,
# there is the possibility to add to existing data, if the file exists. So,
# test to make sure it does not exist.
    die "\nERROR: $outfile already exists. Exiting.\n";
}
open my $out, ">>", $outfile or die "\nERROR: Could not open file: $outfile";

my ($fasnum, $seqhash) = seqct($infile);

if ($$fasnum >= 1) {
    say "\n========== Searching for ORFs with minimum length of $orflen.";
} else {
    die "\nERROR: No sequences were found! Check input. Exiting.\n";
}

my ($iname, $ipath, $isuffix) = fileparse($infile, qr/\.[^.]*/);

while (my ($id, $seq) = each %$seqhash) {
    $fcount++;
    my $orffile = getorf($iname,$isuffix,$fcount,$id,$seq,$find,$nomet);

    if (-s $orffile) {
	$orfseqstot++;
	my $longest_seq = largest_seq($orffile,$sense);

	while (my ($k, $v) = each %$longest_seq) {
	    if (defined $sense) {
		my ($sense_name, $sense_seq) = revcom($k,$v);
		say $out join "\n", ">".$sense_name, $sense_seq;
	    }
	    else {
		say $out join "\n", ">".$k, $v;
	    }
	}
    }
    unlink $orffile;
}
close $out;

my $with_orfs_perc = sprintf("%.2f",$orfseqstot/$$fasnum);
say "\n========== $fcount and $$fasnum sequences in $infile.";
say "\n========== $orfseqstot sequences processed with ORFs above $orflen.";
say "\n========== $with_orfs_perc percent of sequences contain ORFs above $orflen.";

exit;
#
# Subs
#
sub readfq {
    my ($fh, $aux) = @_;
    @$aux = [undef, 0] if (!@$aux);
    return if ($aux->[1]);
    if (!defined($aux->[0])) {
        while (<$fh>) {
            chomp;
            if (substr($_, 0, 1) eq '>' || substr($_, 0, 1) eq '@') {
                $aux->[0] = $_;
                last;
            }
        }
        if (!defined($aux->[0])) {
            $aux->[1] = 1;
            return;
        }
    }
    my ($name, $comm);
    defined $_ && do {
        ($name, $comm) = /^.(\S+)(?:\s+)(\S+)/ ? ($1, $2) : 
	                 /^.(\S+)/ ? ($1, '') : ('', '');
    };
    my $seq = '';
    my $c;
    $aux->[0] = undef;
    while (<$fh>) {
        chomp;
        $c = substr($_, 0, 1);
        last if ($c eq '>' || $c eq '@' || $c eq '+');
        $seq .= $_;
    }
    $aux->[0] = $_;
    $aux->[1] = 1 if (!defined($aux->[0]));
    return ($name, $comm, $seq) if ($c ne '+');
    my $qual = '';
    while (<$fh>) {
        chomp;
        $qual .= $_;
        if (length($qual) >= length($seq)) {
            $aux->[0] = undef;
            return ($name, $comm, $seq, $qual);
        }
    }
    $aux->[1] = 1;
    return ($name, $seq);
}

sub find_prog {
    my $prog = shift;
    my ($path, $err) = capture { system("which $prog"); };
    chomp $path;
    
    if ($path !~ /getorf$/) {
	say 'Couldn\'t find getorf in PATH. Will keep looking.';
	$path = "/usr/local/emboss/latest/bin/getorf";           # path at zcluster
    }

    # Instead of just testing if getorf exists and is executable 
    # we want to make sure we have permissions, so we try to 
    # invoke getorf and examine the output. 
    my ($getorf_path, $getorf_err) = capture { system("$path --help"); };

    given ($getorf_err) {
	when (/Version\: EMBOSS/) { say "Using getorf located at: $path"; }
	when (/^-bash: \/usr\/local\/emboss\/bin\/getorf\: No such file or directory$/) { die "Could not find getorf. Exiting.\n"; }
	when ('') { die "Could not find getorf. Exiting.\n"; }
	default { die "Could not find getorf. Trying installing EMBOSS or adding it's location to your PATH. Exiting.\n"; }
    }
    return $path;
}

sub seqct {
    my $f = shift;
    open my $fh, "<", $f or die "\nERROR: Could not open file: $f\n";
    my ($name, $comm, $seq, $qual);
    my @aux = undef;
    my $seqct = 0;
    my %seqhash;
    while (($name, $comm, $seq, $qual) = readfq(\*$fh, \@aux)) {
	$seqct++;
	# EMBOSS uses characters in identifiers as delimiters, which can produce some
        # unexpected renaming of sequences, so warn that it's not this script doing
        # the renaming.
	given ($name) {
	    when (/\:|\;|\||\(|\)|\.|\s/) { die "WARNING: Identifiers such as '$name' will produce unexpected renaming with EMBOSS."; }
	    when ('') { say 'WARNING: Sequences appear to have no identifiers. Continuing.'; }
	}
	$seqhash{$name} = $seq;
    }
    close $fh;
    return (\$seqct,\%seqhash);
}

sub getorf {
    my ($iname, $isuffix, $fcount, $id, $seq, $find, $nomet) = @_;
    my $tmpiname = $iname."_".$fcount."_XXXX";
    my $cwd = getcwd();
    my $fname = File::Temp->new( TEMPLATE => $tmpiname,
                                 DIR => $cwd,
                                 SUFFIX => $isuffix,
                                 UNLINK => 0);

    open my $fh, ">", $fname or die "\nERROR: Could not open file: $fname\n";

    say $fh join "\n", ">".$id, $seq;

    close $fh;

    my $orffile = $fname."_orfs";

    my $getorfcmd = "$getorf ".
	            "-sequence ".
		    "$fname ".
		    "-outseq ".
		    "$orffile ".
		    "-minsize ".
		    "$orflen ".
		    "-find ".
		    "$find ".
		    "-auto ";

    if (defined $nomet) {
	$getorfcmd .= "-nomethionine";
    }

    my ($stdout, $stderr, @res) = capture { system($getorfcmd); };
    
    unlink $fname;

    return $orffile;
}

sub largest_seq {
    my ($file, $sense) = shift;
 
    open my $fh, "<", $file or die "\nERROR: Could not open file: $file\n";
    
    my ($name, $comm, $seq, $qual);
    my @aux = undef;

    my %seqhash;
    while (($name, $comm, $seq, $qual) = readfq(\*$fh, \@aux)) {
	$seqhash{$name} = $seq;
    }
    close $fh;

    # modified from:
    # http://stackoverflow.com/a/5958473
    my $max;
    my %hash_max;
    keys %seqhash; # reset iterator
    while(my ($key, $value) = each %seqhash) {
	if ( !defined $max || length($value) > $max ) {
	    %hash_max = ();
	    $max = length($value);
	}
	$hash_max{$key} = $value if $max == length($value);
    }
    
    return \%hash_max;
}

sub revcom {
    my ($name, $seq) = @_;

    # If the sequence has been revcom'd 
    # we don't want the ID to say REVERSE. 
    $name =~ s/\(R.*//;   
    my $revcom = reverse $seq;
    $revcom =~ tr/ACGTacgt/TGCAtgca/;
    return ($name, $revcom);
}

sub usage {
    my $script = basename($0);
    print STDERR <<END
USAGE: $script -i infile -o outfile [-l] [-t] [-s] [-nm] [-h] [-m]

Required:
 -i|infile     :       A multifasta file. The longest ORF for each sequence will be reported.
 -o|outfile    :       A file to put the ORFs for each sequence.

Options:
 -l|orflen     :       An interger that will serve as the lower threshold
                       length for ORFs to consider prior to translating.
 -f|find       :       Determines how ORFs are to be reported. Options are one of [0-6]. (Default: 0).
                       See the full documentation for an explanation. 
 -s|sameframe  :       Report all ORFs in the same (sense) frame.
 -nm|nomet     :       Report all ORFs, not just those starting with Methionine (Default: Only report
                       ORFs starting with Methionine).
 -h|help       :       Print a usage statement.
 -m|man        :       Print the full documantion.

END
}

=head1 AUTHOR

S. Evan Staton, C<< <statonse at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests through the project site at 
L<https://github.com/sestaton/HMMER2GO/issues>. I will be notified,
and there will be a record of the issue. Alternatively, I can also be 
reached at the email address listed above to resolve any questions.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HMMER2GO::Run::HMMER


=head1 LICENSE AND COPYRIGHT

Copyright 2014 S. Evan Staton.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


=cut

1;
