package HMMER2GO::Command::getorf;
# ABSTRACT: Run EMBOSS getorf and extract the reading frames.

use 5.010;
use strict;
use warnings;
use HMMER2GO -command;
use Cwd;
use Capture::Tiny       qw(:all);
use IPC::System::Simple qw(system);
use File::Basename;
use File::Temp;
#use Data::Dump::Color;

our $VERSION = '0.18.0';

sub opt_spec {
    return (    
	[ "infile|i=s",    "The fasta files to be translated"                                     ],
	[ "outfile|o=s",   "A file to place the translated sequences"                             ],
	[ "orflen|l=i",    "The minimum length for which to report an ORF"                        ],
        [ "all|a",         "Annotate all the ORFs, not just the longest one"                      ],
	[ "translate|t=i", "Determines what to report for each ORF"                               ],
	[ "sameframe|s",   "Report all ORFs in the same (sense) frame"                            ],
	[ "nomet|nm",      "Do not report only those ORFs starting with Methionine"               ],
	[ "choose|c",      "Pick only one ORF to report if multiple of the same length are found" ], 
	[ "verbose|v",     "Print results to the terminal"                                        ],
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    my $command = __FILE__;
    if ($self->app->global_options->{man}) {
	system([0..5], "perldoc $command");
    }
    else {
	$self->usage_error("Too few arguments.") unless $opt->{infile} && $opt->{outfile};
    }
} 

sub execute {
    my ($self, $opt, $args) = @_;

    exit(0) if $self->app->global_options->{man};
    
    my $result = _run_getorf($opt);
}

sub _run_getorf {
    my ($opt) = @_;

    my $getorf = _find_getorf();
    my ($infile, $outfile, $find, $orflen, $allorfs, $nomet, $sense, $verbose, $choose) = 
	@{$opt}{qw(infile outfile translate orflen all nomet sameframe verbose choose)};

    if (-e $outfile) { 
        # Because we are appending the ORFs from each sequence to the same output,
        # there is the possibility to add to existing data, if the file exists. So,
        # test to make sure it does not exist.
	say STDERR "\n[ERROR]: $outfile already exists. Exiting.\n";
	exit 1;
    }

    my $fcount = 0;
    my $orfseqstot = 0;
    $choose //= 0;
    $find //= 0;
    $orflen //= 80;
    

    my ($fasnum, $seqhash, $idmap) = _seqct($infile);

    if ($fasnum >= 1) {
	say "\n========== Searching for ORFs with minimum length of $orflen." if $verbose;
    } 
    else {
	say STDERR "\n[ERROR]: No sequences were found! Check input. Exiting.\n";
	exit 1;
    }

    open my $out, ">>", $outfile or die "\n[ERROR]: Could not open file: $outfile\n";
    my ($iname, $ipath, $isuffix) = fileparse($infile, qr/\.[^.]*/);

    for my $seqname (keys %$seqhash) { 
	$fcount++;
	my $orffile = _getorf($getorf, $iname, $isuffix, $fcount, 
			      $seqname, $seqhash->{$seqname}, $find, $nomet, $orflen);

	if (-s $orffile) {
	    $orfseqstot++;
	    my $seqs = _sort_seqs($orffile, $sense, $allorfs, $choose);
	    
	    # sort to keep seqs with multiple ORFs together in the output
	    for my $name (sort keys %$seqs) {
		my $ntseq = $seqs->{$name};
		$name =~ s/\_\d+\s+.*//;
		$name = exists $idmap->{$name} ? $idmap->{$name} : $name;
		if (defined $sense) {
		    my ($sense_name, $sense_seq) = _revcom($name, $ntseq);
		    $sense_seq =~ s/.{60}\K/\n/g;
		    say $out join "\n", ">".$sense_name, $sense_seq;
		}
		else {
		    $ntseq =~ s/.{60}\K/\n/g;
		    say $out join "\n", ">".$name, $ntseq;
		}
	    }
	}
	unlink $orffile;
    }
    close $out;

    if ($verbose) {
	my $with_orfs_perc = sprintf("%.2f",$orfseqstot/$fasnum);
	say "\n========== $fcount and $$fasnum sequences in $infile.";
	say "\n========== $orfseqstot sequences processed with ORFs above $orflen.";
	say "\n========== $with_orfs_perc percent of sequences contain ORFs above $orflen.";
    }

    return;
}

sub _find_getorf {
    my $getorf;
    my @path = split /:|;/, $ENV{PATH};

    for my $p (@path) {
	my $prog = File::Spec->catfile($p, 'getorf');

	if (-e $prog) {
	    $getorf = $prog;
	    last;
	}
    }

    if (-e $getorf && -x $getorf) {
	return $getorf;
    }
    else { 
	say STDERR "\n[ERROR]: Could not find getorf. ".
	    "Trying installing EMBOSS or adding it's location to your PATH. Exiting.\n";
	exit 1;
    }
}

sub _seqct {
    my ($f) = @_;

    my $fh = _get_fh($f);
    my $seqct = 0;
    my (%seqhash, %idmap);

    { 
	local $/ = '>';
	while (my $line = <$fh>) {
	    chomp $line;
	    my ($name, @seqparts) = split /\n/, $line;
	    my $seq = join '', @seqparts;
	    next unless defined $name && defined $seq;
	    $name =~ s/\s+$//;
	    # EMBOSS uses characters in identifiers as delimiters, which can produce some
	    # unexpected renaming of sequences, so warn that it's not this script doing
	    # the renaming.
	    my $namefix;
	    if ($name =~ /\:|\;|\||\(|\)|\[|\]|\.|\s|\\|\//) { 
		my $namefix = $name;
		$namefix =~ s/\s+.*//;
		$namefix =~ s/\:|\;|\||\(|\)|\[|\]|\.|\\|\//_/g;

		# Way too verbose. We will use the original IDs in the output, so there is no reason to warn.
		#say STDERR "\n[WARNING]: Identifiers such as '$name' will produce unexpected renaming with EMBOSS. ".
		#".Changing to '$namefix'.";
		$idmap{$namefix} = $name;
		$name = $namefix;
	    }
	    elsif ($name eq '') { 
		say STDERR "\n[WARNING]: Sequences appear to have no identifiers. Continuing."; 
	    }

	    $seqhash{$name} = $seq;
	    $seqct++;
	}
	close $fh;
    }

    return ($seqct, \%seqhash, \%idmap);
}

sub _sort_seqs {
    my ($file, $sense, $allorfs, $choose) = @_;
 
    my $fh = _get_fh($file);
    my %seqhash;

    { 
	local $/ = '>';
	while (my $line = <$fh>) {
	    chomp $line;
	    my ($name, @seqparts) = split /\n/, $line;
	    my $seq = join '', @seqparts;
	    next unless defined $name && defined $seq;
	    $seqhash{$name} = $seq;
	}
    }
    close $fh;

    if (!$allorfs) {
	my $max;
	my %hash_max;
	keys %seqhash; # reset iterator

	for my $key (keys %seqhash) { 
	    if ( !defined $max || length($seqhash{$key}) > $max ) {
		%hash_max = ();
		$max = length($seqhash{$key});
	    }
	    $hash_max{$key} = $seqhash{$key} if $max == length($seqhash{$key});
	}
	my @orfs = keys %hash_max;
	if (@orfs > 1) {
	    if ($choose) {
		my %one_seq;
		for my $k (keys %hash_max) {
		    if ($k !~ /reverse/i) { 
			$one_seq{$k} = $hash_max{$k};
			last;
		    }
		}
		if (%one_seq) {
		    return \%one_seq;
		}
		else {
		    my $k = (keys %hash_max)[0];
		    $one_seq{$k} = $hash_max{$k};
		    return \%one_seq;
		}
	    }
	    else {
		say STDERR "\n[WARNING]: More than one ORF has the same max length, will report all ORFs with ".
		    "max length for this sequence.";
		say STDERR "The ORF identifiers are: ", join ", ", @orfs;
	    }
	}
	return \%hash_max;
    }
    else {
	return \%seqhash;
    }
}

sub _getorf {
    my ($getorf, $iname, $isuffix, $fcount, $id, $seq, $find, $nomet, $orflen) = @_;
    my $tmpiname = $iname."_".$fcount."_XXXX";
    my $cwd = getcwd();
    my $fname = File::Temp->new( TEMPLATE => $tmpiname,
                                 DIR => $cwd,
                                 SUFFIX => $isuffix,
                                 UNLINK => 0);

    open my $fh, ">", $fname or die "\n[ERROR]: Could not open file: $fname\n";
    say $fh join "\n", ">".$id, $seq;
    close $fh;

    my $orffile = $fname."_orfs";

    my @getorfcmd = ($getorf, "-sequence", $fname, "-outseq", $orffile, "-minsize", $orflen, 
		     "-find", $find, "-auto");
    
    if (defined $nomet) {
	push @getorfcmd, "-nomethionine";
    }

    my ($stdout, $stderr, @res) = capture { system([0..5], @getorfcmd); };

    unlink $fname;

    return $orffile;
}

sub _revcom {
    my ($name, $seq) = @_;

    # If the sequence has been revcom'd 
    # we don't want the ID to say REVERSE. 
    $name =~ s/\(R.*// if $name =~ /\(REVERSE/i;   

    if ($seq =~ /[atcg]/i) {
	my $revcom = reverse $seq;
	$revcom =~ tr/ACGTacgt/TGCAtgca/;
	$seq = $revcom;
	#return ($name, $revcom);
    }
    else {
	say STDERR "\n[WARNING]: Not going to reverse protein sequence.";
	#return ($name, $seq);
    }

    return ($name, $seq);
}

sub _get_fh {
    my ($file) = @_;
    my $fh;
    if ($file =~ /\.gz$/) {
	open $fh, '-|', 'zcat', $file or die "\n[ERROR]: Could not open file: $file\n";
    }
    elsif ($file =~ /\.bz2$/) {
	open $fh, '-|', 'bzcat', $file or die "\n[ERROR]: Could not open file: $file\n";
    }
    elsif ($file =~ /^-$|STDIN/) {
	open $fh, '< -' or die "\n[ERROR]: Could not open STDIN\n";
    }
    else {
	open $fh, '<', $file or die "\n[ERROR]: Could not open file: $file\n";
    }
    return $fh;
}

1;
__END__

=pod

=head1 NAME
                                                                       
 hmmer2go getorf - Run EMBOSS getorf and extract the reading frames.

=head1 SYNOPSIS    

 ## get the longest translated ORF between stop codons
 hmmer2go getorf -i seqs.fas -o seqs_aa.faa

 ## get the nucleotides for the longest ORF between stop codons
 hmmer2go getorf -i seqs.fas -o seqs_nt.fas -t 2

=head1 DESCRIPTION
                                                                   
 Translate a nucleotide multi-fasta file in all 6 frames and select 
 the longest ORF, by default, or all ORFs for each sequence. The ORFs are 
 reported as nucleotide sequences by default, but translated may also be 
 reported. The minimum ORF length to report can be given as an option.

=head1 DEPENDENCIES

 This command uses EMBOSS, so it must be installed. 
 (The latest is v6.5.7 as of this writing).

=head1 AUTHOR 

S. Evan Staton, C<< <evan at evanstaton.com> >>

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

=item -a, --all

 By default, the 'hmmer2go getorf' command will only return the longest ORF for each input sequence.
 If you have genomic contigs for example, this is not what you want because you would
 miss most of the genes or domains. By specifying this option, you can return all ORFs
 for each input sequence above a certain length (see the '--orflen' option above).

=item -t, --translate

 Determines what to report for each ORF. Argument may be one of [0-6]. (Default: 0).
 The descriptions below are copied straight from EMBOSS getorf help menu so there is no confusion.
 The default option ('0') takes the same behavior as EMBOSS sixpack and produces
 the same output. N.B. getorf seems to treat [^ATCG] characters differently than
 sixpack, so a translation from getorf may be a residue longer in my tests.

   Argument    Description

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

=item -c, --choose

If more than one ORF of the same length exists, choose one (NB: experimental).

=item -h, --help

Print a usage statement. 

=item -m, --man

Print the full documentation.

=back

=cut
