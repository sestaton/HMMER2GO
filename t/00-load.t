#!perl -T
use 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'BlastQueue::Role::File' ) || print "Bail out!\n";
    use_ok( 'BlastQueue::Run::WuBlast' ) || print "Bail out!\n";
    use_ok( 'BlastQueue' ) || print "Bail out!\n";
}

diag( "Testing BlastQueue::Role::File $BlastQueue::Role::File::VERSION, Perl $], $^X" );
