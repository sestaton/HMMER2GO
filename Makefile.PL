use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

if (eval ($ExtUtils::MakeMaker::VERSION) <= 6.55) {
    print "\n[ERROR]: ExtUtils::MakeMaker >= 6.5503 is required to build the package correctly.\n";
    print "The installed version is $ExtUtils::MakeMaker::VERSION.\n";
    print "Install the latest ExtUtils::MakeMaker and try again. Exiting.\n";
    exit(1);
}

#BEGIN {
#    system("chmod +x bin/hmmer2go");
#}

WriteMakefile(
    NAME             => 'HMMER2GO',
    AUTHOR           => q{S. Evan Staton <evan at evanstaton.com>},
    VERSION_FROM     => 'bin/hmmer2go',
    LICENSE          => 'MIT',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.5503,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'IPC::System::Simple'       => 1.21,
	'App::Cmd'                  => 0.323,
	'HTTP::Tiny'                => 0,
	'Try::Tiny'                 => 0,
	'Capture::Tiny'             => 0,
	'XML::LibXML'               => 0,
	'HTML::TableExtract'        => 0,
	'IO::Uncompress::Gunzip'    => 0,
	'IO::Uncompress::Bunzip2'   => 0,
        'IO::Compress::Gzip'        => 0,
        'IO::Compress::Bzip2'       => 0,
        'File::Copy'                => 0,
        'Net::SSLeay'               => 0,
        'IO::Socket::SSL'           => 0,
        'Bio::DB::Taxonomy::entrez' => 0,
    },
    INST_SCRIPT => 'blib/bin',
    EXE_FILES   => [ 'bin/hmmer2go' ],
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    test  => { TESTS => 't/*.t' },
);

