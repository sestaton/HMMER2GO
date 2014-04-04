package Getorf;

use Moo;
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
    
package main;

use strict;
use warnings;

my $hmm2go = Getorf->new_with_options;

