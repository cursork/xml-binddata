use strict;
use warnings;

use File::Spec;
use FindBin;
use Test::More;

use_ok 'XML::BindData::Backwards';

my $tests = require File::Spec->catfile($FindBin::Bin, 'tests.pl');

foreach my $t (@$tests) {
	my ($source_xml, $output, $data, $msg, $opts) = @$t;

	local $TODO = $opts->{'reason'} // 'Not yet supported'
		if ref $opts && $opts->{'skip'} eq 'backwards';

	my $res = XML::BindData::Backwards->unbind($source_xml, $data);
	is_deeply($res, $output, $msg);
}

done_testing;

