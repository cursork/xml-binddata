use strict;
use warnings;

use File::Spec;
use FindBin;
use Test::More;

use_ok 'XML::BindData';

my $tests = require File::Spec->catfile($FindBin::Bin, 'tests.pl');

foreach my $t (@$tests) {
	my ($source_xml, $data, $output, $msg) = @$t;
	is(XML::BindData->bind($source_xml, $data), $output, $msg);
}

done_testing;
