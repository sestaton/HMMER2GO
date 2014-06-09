package HMMER2GO::Command::getorf;
# ABSTRACT: Run EMBOSS getorf and extract longest reading frames.

use 5.012;
use strict;
use warnings;
use HMMER2GO -command;
use Cwd;
use Capture::Tiny qw(:all);
use IPC::System::Simple qw(system);
use File::Basename;
use File::Temp;

sub opt_spec {
    return (    
	[ "infile|i=s",  "The fasta files to be translated"                       ],
	[ "outfile|o=s", "A file to place the translated sequences"               ],
	[ "orflen|l=i",  "The minimum length for which to report an ORF"          ],
	[ "translate|t", "Determines what to report for each ORF"                 ],
	[ "sameframe|s", "Report all ORFs in the same (sense) frame"              ],
	[ "nomet|nm",    "Do not report only those ORFs starting with Methionine" ],
	[ "verbose|v",   "Print results to the terminal"                          ],
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;
       
    $self->usage_error("Too few arguments.") unless $opt->{infile} && $opt->{outfile};
} 

sub execute {
    my ($self, $opt, $args) = @_;

    my $infile  = $opt->{infile};
    my $outfile = $opt->{outfile};
    my $orflen  = $opt->{orflen};
    my $find    = $opt->{translate};
    my $nomet   = $opt->{nomet};
    my $sense   = $opt->{sameframe};
    my $verbose = $opt->{verbose};

    my $getorf = _find_prog("getorf");

    my $result = _run_getorf($getorf, $infile, $outfile, $find, $orflen, $nomet, $sense, $verbose);
}

sub _run_getorf {
    my ($getorf, $infile, $outfile, $find, $orflen, $nomet, $sense, $verbose) = @_;

    if (-e $outfile) { 
        # Because we are appending the ORFs from each sequence to the same output,
        # there is the possibility to add to existing data, if the file exists. So,
        # test to make sure it does not exist.
	die "\nERROR: $outfile already exists. Exiting.\n";
    }

    my $fcount = 0;
    my $orfseqstot = 0;
    $find //= 0;
    $orflen //= 80;

    open my $out, ">>", $outfile or die "\nERROR: Could not open file: $outfile";

    my ($fasnum, $seqhash) = _seqct($infile);

    if ($$fasnum >= 1) {
	say "\n========== Searching for ORFs with minimum length of $orflen." if $verbose;
    } 
    else {
	die "\nERROR: No sequences were found! Check input. Exiting.\n";
    }

    my ($iname, $ipath, $isuffix) = fileparse($infile, qr/\.[^.]*/);

    while (my ($id, $seq) = each %$seqhash) {
	$fcount++;
	my $orffile = _getorf($getorf, $iname, $isuffix, $fcount, $id, $seq, $find, $nomet, $orflen);

	if (-s $orffile) {
	    $orfseqstot++;
	    my $longest_seq = _largest_seq($orffile,$sense);

	    while (my ($k, $v) = each %$longest_seq) {
		if (defined $sense) {
		    my ($sense_name, $sense_seq) = _revcom($k,$v);
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

    if ($verbose) {
	my $with_orfs_perc = sprintf("%.2f",$orfseqstot/$$fasnum);
	say "\n========== $fcount and $$fasnum sequences in $infile.";
	say "\n========== $orfseqstot sequences processed with ORFs above $orflen.";
	say "\n========== $with_orfs_perc percent of sequences contain ORFs above $orflen.";
    }
}

sub _readfq {
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

sub _find_prog {
    my $prog = shift;
    my ($path, $err) = capture { system([0..5], "which $prog"); };
    chomp $path;
    
    if ($path !~ /$prog$/) {
	say "Couldn\'t find $prog in PATH. Will keep looking.";
	$path = "/usr/local/emboss/latest/bin/getorf";           # path at zcluster
    }

    # Instead of just testing if getorf exists and is executable 
    # we want to make sure we have permissions, so we try to 
    # invoke getorf and examine the output. 
    my ($getorf_path, $getorf_err) = capture { system([0..5], "$path --help"); };

    if ($getorf_err =~ /Version\: EMBOSS/) { 
	say "Using getorf located at: $path"; 
    }
    elsif ($getorf_err =~ /^-bash: \/usr\/local\/emboss\/bin\/getorf\: No such file or directory$/) { 
	die "Could not find getorf. Exiting.\n"; 
    }
    elsif ($getorf_err eq '') { 
	die "Could not find getorf. Exiting.\n"; 
    }
    else { 
	die "Could not find getorf. ".
	    "Trying installing EMBOSS or adding it's location to your PATH. Exiting.\n"; 
    }
    return $path;
}

sub _seqct {
    my $f = shift;
    open my $fh, "<", $f or die "\nERROR: Could not open file: $f\n";
    my ($name, $comm, $seq, $qual);
    my @aux = undef;
    my $seqct = 0;
    my %seqhash;
    while (($name, $comm, $seq, $qual) = _readfq(\*$fh, \@aux)) {
	$seqct++;
	# EMBOSS uses characters in identifiers as delimiters, which can produce some
        # unexpected renaming of sequences, so warn that it's not this script doing
        # the renaming.
	if ($name =~ /\:|\;|\||\(|\)|\.|\s/) { 
	    die "ERROR: Identifiers such as '$name' will produce unexpected renaming with EMBOSS. Exiting."; 
	}
	elsif ('') { 
	    say 'WARNING: Sequences appear to have no identifiers. Continuing.'; 
	}
	$seqhash{$name} = $seq;
    }
    close $fh;
    return (\$seqct,\%seqhash);
}

sub _largest_seq {
    my ($file, $sense) = @_;
 
    open my $fh, "<", $file or die "\nERROR: Could not open file: $file\n";
    
    my ($name, $comm, $seq, $qual);
    my @aux = undef;

    my %seqhash;
    while (($name, $comm, $seq, $qual) = _readfq(\*$fh, \@aux)) {
	$seqhash{$name} = $seq;
    }
    close $fh;

    # modified from:
    # http://stackoverflow.com/a/5958473
    my $max;
    my %hash_max;
    keys %seqhash; # reset iterator
    while (my ($key, $value) = each %seqhash) {
	if ( !defined $max || length($value) > $max ) {
	    %hash_max = ();
	    $max = length($value);
	}
	$hash_max{$key} = $value if $max == length($value);
    }
    
    return \%hash_max;
}

sub _getorf {
    my ($getorf, $iname, $isuffix, $fcount, $id, $seq, $find, $nomet, $orflen) = @_;
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

    my ($stdout, $stderr, @res) = capture { system([0..5], $getorfcmd); };

    unlink $fname;

    return $orffile;
}

sub _revcom {
    my ($name, $seq) = @_;

    # If the sequence has been revcom'd 
    # we don't want the ID to say REVERSE. 
    $name =~ s/\(R.*//;   
    my $revcom = reverse $seq;
    $revcom =~ tr/ACGTacgt/TGCAtgca/;
    return ($name, $revcom);
}

1;
__END__

=pod

=head1 NAME
                                                                       
 hmmer2go getorf - Run EMBOSS getorf and extract longest reading frames.

=head1 SYNOPSIS    

 hmmer2go getorf -i seqs.fas -o seqs_trans.faa

=head1 DESCRIPTION
                                                                   
 Translate a nucleotide multi-fasta file in all 6 frames and select 
 the longest ORF for each sequence. The ORFs are reported as nucleotide
 sequences by default, but translated may also be reported. The minimum 
 ORF length to report can be given as an option.

=head1 DEPENDENCIES

 This command uses EMBOSS, so it must be installed. 
 (The latest is v6.5.7 as of this writing).

=head1 AUTHOR 

S. Evan Staton                                                

=head1 CONTACT
 
statonse at gmail dot com

=head1 REQUIRED ARGUMENTS

=over 2

=item -i, --infile

The fasta files to be translated.

=item -o, --outfile

A file to place the translated sequences.

=back

=head1 OPTIONS

=over 2

=item -l, --orflen

 The minimum length for which to report an ORF (Default: 80).
 Lowering this value will not likely result in any significant hits 
 from iprscan or other search programs (though there may be a reason to do so).

=item -f, --find

 Determines what to report for each ORF. Argument may be one of [0-6]. (Default: 0).
 Descriptions copied straight from EMBOSS getorf help menu so there is no confusion.
 The default option ('0') takes the same behavior as EMBOSS sixpack and produces
 the same output. N.B. getorf seems to treat [^ATCG] characters differently than
 getorf, so a translation from getorf may be a residue longer in my tests.

=item I<   Argument    Description>

 0           Translation of regions between STOP codons.
 1           Translation of regions between START and STOP codons.
 2           Nucleic sequences between STOP codons.
 3           Nucleic sequences between START and STOP codons.
 4           Nucleotides flanking START codons.
 5           Nucleotides flanking initial STOP codons.
 6           Nucleotides flanking ending STOP codons.

=item -s, --sameframe

Report all ORFs in the same (sense) frame.

=item -nm, --nomet

Do not report only those ORFs starting with Methionine (Default: Yes).

=item -h, --help

Print a usage statement. 

=item -m, --man

Print the full documentation.

=back

=cut
