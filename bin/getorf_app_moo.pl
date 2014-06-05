#!/usr/bine/env perl

use 5.014;
use strict;
use warnings;

{
    package Getorf::Options;

    use Moo::Role;
    use MooX::Options;
    use Cwd;
    use File::Basename;
    use File::Temp;
    use Path::Class::File;

    option 'infile' => ( 
	is       => 'ro', 
	format   => 's', 
        required => 1, 
        short    => 'i',
        doc      => 'The fasta files to be translated',
    );

    option 'outfile' => ( 
        is       => 'ro', 
        format   => 's', 
        required => 1, 
        short    => 'o',
        doc      => 'A file to place the translated sequences',
    );

    option 'orflen' => ( 
        is      => 'ro', 
        format  => 'i', 
        default => 80, 
        short   => 'l',
        doc     => 'The minimum length for which to report an ORF',
    );

    option 'translate' => ( 
        is    => 'ro', 
        short => 't',
        doc   => 'Determines what to report for each ORF',
    );

    option 'sameframe' => (
        is    => 'ro', 
        short => 's',
        doc   => 'Report all ORFs in the same (sense) frame',
    );

    option 'nomet' => ( 
        is    => 'ro',
        short => 'nm',
        doc   => 'Do not report only those ORFs starting with Methionine',
    );
}

{
    package Getorf::Cmd::getorf;
    use Moo;
    use MooX::Cmd;
    use MooX::Options;
    use Cwd;
    use File::Temp;
    use IPC::System::Simple qw(system);
    use Try::Tiny;

    with 'Getorf::Options';

    sub execute {
	my $self = shift;

	#my ($infile, $fcount, $id, $seq, $find, $nomet) = @_;

	require File::Temp;
	require File::Basename;
	
	#my ($iname, $ipath, $isuffix) = fileparse($self->infile, qr/\.[^.]*/);
	#my $tmpiname = $iname."_".$fcount."_XXXX";
	#my $cwd = getcwd();
 
	#my $fname = File::Temp->new( TEMPLATE => $tmpiname,
		#		     DIR      => $cwd,
		#		     SUFFIX   => $isuffix,
		#		     UNLINK   => 0);

	#open my $fh, ">", $fname or die "\nERROR: Could not open file: $fname\n";

	#say $fh join "\n", ">".$id, $seq;

	#close $fh;

	my $infile  = $self->infile;
	my $orffile = $self->outfile;
	my $orflen  = $self->orflen;
	my $find    = $self->find;
	$orflen     //= 80;
	$find       //= 0;

	my $getorfcmd = "getorf ".
	                "-sequence ".
		        "$infile ".
			"-outseq ".
			"$orffile ".
			"-minsize ".
			"$orflen ".
			"-find ".
			"$find ".
			"-auto ";

	if (defined $self->nomet) {
	    $getorfcmd .= "-nomethionine";
	}

	my $exit_code;
	try {
	    $exit_code = system([0..5], $getorfcmd);
	}
	catch {
	    confess "ERROR: getorf exited with exit code: $exit_code. Here is the exception: $_";
	};

	#unlink $fname;

	return $orffile;
    }
}

{
    package Getorf;

    use Moo;
    use MooX::Cmd;
    use MooX::Options;
    use File::Spec;
    use Try::Tiny;
    use Carp 'confess';

    #with 'Getorf::Options';

    has 'getorf_exec' => (
	is     => 'rw',
	traits => ['NoGetopt'],
	builder => \&find_getorf,
	
    );

    sub execute {
        my $self = shift;
        my ($args, $chain) = @_;
        die "Need to specify a sub-command!\n";
    }

    sub find_getorf {
        my $self = shift;
        my @path = split /:|;/, $ENV{PATH};

        for my $p (@path) {
	    my $exe = File::Spec->catfile($p, 'getorf');
	    
	    if (-e $exe && -x $exe) {
		$self->getorf_exec($exe);
	    }
	}

	try {
	    die unless $self->getorf_exec;
	}
	catch {
	    confess "Unable to find getorf. Check you PATH to see that it is installed. Exiting.";
	    exit(1);
        };
    }
}

my $obj = Getorf->new_with_cmd;

#say $obj->getorf_exec;
