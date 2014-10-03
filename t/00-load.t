#!/usr/bin/env perl

use 5.010;
use strict;
use warnings FATAL => 'all';
use IPC::System::Simple qw(capture);
use Test::More tests => 3;

BEGIN {
    use_ok( 'HMMER2GO' ) || print "Bail out!\n";
}

diag( "Testing HMMER2GO $HMMER2GO::VERSION, Perl $], $^X" );

my $hmmer2go = "bin/hmmer2go";
ok(-x $hmmer2go, 'Can execute hmmer2go');

my @menu = capture([0..5], "bin/hmmer2go help");

my $progs = 0;
for my $command (@menu) {
    next if $command =~ /^ *$|^Available/;
    $command =~ s/^\s+//;
    my ($prog, $desc) = split /\:/, $command;
    ++$progs if $prog;
}

is ($progs, 8, 'Correct number of subcommands listed');

done_testing();
