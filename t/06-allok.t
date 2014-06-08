#!/usr/bin/env perl

use 5.012;
use strict;
use warnings FATAL => 'all';
use IPC::System::Simple qw(system capture);
use Test::More tests => 7;

for my $file (glob("t/test_data/*")) {
    if ($file =~ /pfam2go/) {
	like($file, qr/pfam2go/, 'Expect pfam2go mapping file in test results');
	# unlink $file;
    }
    elsif ($file =~ /\.hmm$/) {
	like($file, qr/\.hmm$/, 'Expected Pfam database in test results');
	#unlink $file;
    }
    elsif ($file =~ /\.hmm.gz$/) {
        like($file, qr/\.gz$/, 'Expected Pfam database in test results');
	#unlink $file
    }
    elsif ($file =~ /\.h3f$/) {
        like($file, qr/\.h3f$/, 'Expected Pfam database in test results');
        #unlink $file
    }
    elsif ($file =~ /\.h3i$/) {
        like($file, qr/\.h3i$/, 'Expected Pfam database in test results');
        #unlink $file
    }
    elsif ($file =~ /\.h3m$/) {
        like($file, qr/\.h3m$/, 'Expected Pfam database in test results');
        #unlink $file
    }
    elsif ($file =~ /\.h3p$/) {
        like($file, qr/\.h3p$/, 'Expected Pfam database in test results');
        #unlink $file
    }
}

done_testing();
