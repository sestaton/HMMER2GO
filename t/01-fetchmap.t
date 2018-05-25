use 5.010;
use strict;
use warnings FATAL => 'all';
use File::Spec;
use IPC::System::Simple qw(system capture);

use Test::More tests => 2;

my $hmmer2go = File::Spec->catfile('blib', 'bin', 'hmmer2go');
my @menu     = capture([0..5], "$hmmer2go help fetchmap");

my $opts = 0;
my $file = File::Spec->catfile('t', 'test_data', 'pfam2go');

for my $opt (@menu) {
    next if $opt =~ /^hmmer2go|^ *$/;
    $opt =~ s/^\s+//;
    my ($option, $desc) = split /\s+/, $opt;
    ++$opts if $option =~ /^-/;
    #    say STDERR $option;
}

is( $opts, 1, 'Correct number of options for hmmer2go fetchmap' );

my $devtests = 0;
if (defined $ENV{HMMER2GO_ENV} && $ENV{HMMER2GO_ENV} eq 'development') {
    $devtests = 1;
}

SKIP: {
    skip 'skip network tests', 1 unless $devtests;
    my $result = system([0..5], "$hmmer2go fetchmap -o $file");

    ok( -e $file, 'Successfully fetched pfam2go mappings' );
}

done_testing();
