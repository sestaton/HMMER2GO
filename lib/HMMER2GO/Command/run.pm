package HMMER2GO::Command::run;
# ABSTRACT: Run HMMscan on translated ORFs against Pfam database.

use 5.010;
use strict;
use warnings;
use HMMER2GO -command;
use Cwd;
use IPC::System::Simple     qw(capture system);
use IO::Uncompress::Bunzip2 qw(bunzip2 $Bunzip2Error);
use IO::Uncompress::Gunzip  qw(gunzip $GunzipError);
use File::Basename;
use Try::Tiny;

sub opt_spec {
    return (    
	[ "program|p=s",  "The program to run for domain identification (NOT IMPLEMENTED: Defaults to hmmscan)"          ],
	[ "infile|i=s",   "The fasta file of translated amino acid sequences"     ],
	[ "cpus|n=i",     "The number of CPUs to use for the search"              ],
	[ "database|d=s", "The database to search against (typically Pfam-A.hmm)" ],
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
	    unless $opt->{infile} && $opt->{database};
    }
} 

sub execute {
    my ($self, $opt, $args) = @_;

    exit(0) if $self->app->global_options->{man};
    my $program  = $opt->{program};
    my $infile   = $opt->{infile};
    my $database = $opt->{database};
    my $cpus     = $opt->{cpus};

    my $hmmscan = _find_prog("hmmscan");

    my $result = _run_hmmscan($hmmscan, $infile, $database, $cpus);
}

sub _run_hmmscan {
    my ($hmmscan, $infile, $database, $cpus) = @_;

    my $tempfile;
    if ($infile =~ /\.gz$|\.bz2/) {
	$tempfile = _uncompress_input($infile);
    }

    my ($iname, $ipath, $isuffix) = fileparse($infile, qr/\.[^.]*/);
    my ($dname, $dpath, $dsuffix) = fileparse($database, qr/\.[^.]*/);
    my $outfile   = $iname."_".$dname.".out";
    my $domtblout = $iname."_".$dname.".domtblout";
    my $tblout    = $iname."_".$dname.".tblout";

    $cpus //= 1;

    if (-e $outfile) { 
	die "\nERROR: $outfile already exists. Exiting.\n";
    }
    
    my @hmmscan_cmd = ($hmmscan, "-o", $outfile, "--tblout", $tblout, "--domtblout", $domtblout,
		       "--acc", "--noali", "--cpu", $cpus, $database);

    if ($infile =~ /\.gz|\.bz2/) {
	push @hmmscan_cmd, $tempfile;
    }
    else {
	push @hmmscan_cmd, $infile;
    }

    my $exit_value;
    try {
	$exit_value = system([0..5], @hmmscan_cmd);
    }
    catch {
	die "\nERROR: hmmscan exited with exit value $exit_value. Here is the exception: $_\n";
    };

    unlink $tempfile if defined $tempfile && -e $tempfile;
}

sub _uncompress_input {
    my ($file) = @_;

    my $cwd = getcwd();
    my $unc_filename;
    if ($file =~ /\.gz$/) {
	my $infile = $file;
	$infile =~ s/\.gz//;
	my ($iname, $ipath, $isuffix) = fileparse($infile, qr/\.[^.]*/);
	my $ucfile = File::Temp->new( TEMPLATE => $iname."_XXXX",
				      DIR      => $cwd,
				      SUFFIX   => $isuffix,
				      UNLINK   => 0 );

	$unc_filename = $ucfile->filename;
	gunzip $file => $unc_filename or die "gunzip failed: $GunzipError\n";
    }
    elsif ($file =~ /\.bz2$/) {
	my $infile = $file;
	$infile =~ s/\.bz2//;
        my ($iname, $ipath, $isuffix) = fileparse($infile, qr/\.[^.]*/);
        my $ucfile = File::Temp->new( TEMPLATE => $iname."_XXXX",
                                      DIR      => $cwd,
                                      SUFFIX   => $isuffix,
                                      UNLINK   => 0 );

        $unc_filename = $ucfile->filename;
        bunzip2 $file => $unc_filename or die "bunzip2 failed: $Bunzip2Error\n";
    }
    return $unc_filename;
}

sub _find_prog {
    my ($prog) = @_;
    my @path = split /:|;/, $ENV{PATH};

    my $exepath;

    for my $p (@path) {
        my $exe = File::Spec->catfile($p, $prog);
        
	if (-e $exe) {
	    $exepath = $exe;
	}
    }

    if (-e $exepath && -x $exepath) {
        return $exepath;
    }
    else { 
        die "Could not find $prog. ".
            "Trying installing HMMER3 or adding it's location to your PATH. Exiting.\n";
    }
}

1;
__END__

=pod

=head1 NAME
                                                                       
 hmmer2go run - Run HMMscan on translated ORFs against Pfam database

=head1 SYNOPSIS    

 hmmer2go run -i seqs.fas -db Pfam-A.hmm -n 4

=head1 DESCRIPTION
  
 This command runs the HMMER program 'hmmscan' against a set of profile HMMs. The input
 is a set of amino acid sequences, typically translated open reading frames. The set of HMMs
 to search against is optional but the most common usage would be to use the Pfam-A set. Additional
 arguments to 'hmmscan' such as the number of CPUs to use for the search may be passed to hmmer2go search.

=head1 DEPENDENCIES

 HMMER version 3+ is required for this command to work.
 (The latest is v3.1b1 as of this writing)

=head1 AUTHOR 

S. Evan Staton, C<< <statonse at gmail.com> >>

=head1 REQUIRED ARGUMENTS

=over 2

=item -i, --infile

The fasta file to be translated.

=back

=head1 OPTIONS

=over 2

=item -p, --program

 The domain identification progam to use. Currently, only HMMscan is
 used. Therefore, this option does nothing at the moment, 
 though InterProScan (and possibly others) will be added very soon.

=item -n, --cpus

 The number of CPUs to use for the HMMscan search.

=item -h, --help

Print a usage statement. 

=item -m, --man

Print the full documentation.

=back

=cut
