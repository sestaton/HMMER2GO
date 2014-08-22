#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use IPC::System::Simple qw(system capture);
use Test::More tests => 2;

my @menu = capture([0..5], "bin/hmmer2go help fetchmap");

my $opts = 0;
my $file = "t/test_data/pfam2go";

for my $opt (@menu) {
    next if $opt =~ /^hmmer2go|^ *$/;
    $opt =~ s/^\s+//;
    my ($option, $desc) = split /\s+/, $opt;
    ++$opts if $option;
}

is($opts, 1, 'Correct number of options for hmmer2go fetchmap');

my $result = system([0..5], "bin/hmmer2go fetchmap -o $file");

ok(-e $file, 'Successfully fetched pfam2go mappings');

done_testing();
