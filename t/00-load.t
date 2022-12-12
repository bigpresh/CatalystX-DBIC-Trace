#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'CatalystX::Profile::NYTProf' ) || print "Bail out!\n";
}

diag( "Testing CatalystX::Profile::NYTProf $CatalystX::Profile::NYTProf::VERSION, Perl $], $^X" );
