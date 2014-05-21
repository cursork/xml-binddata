use strict;
use warnings;

use Test::More;
use Test::Mock::Simple;

use_ok 'XML::BindData';

my $counter = 0;
my $mock = Test::Mock::Simple->new(module => 'XML::BindData');
$mock->add('_get' => sub { $counter++; return []; });

is(
	XML::BindData->bind(
		"<?xml version=\"1.0\"?><foo><bar tmpl-each=\"bar\" tmpl-bind=\"this\"/></foo>",
		{ bar => [ ] }
	),
	"<?xml version=\"1.0\"?>\n<foo/>\n"
);
is($counter, 1, 'Terminated correctly after each');

done_testing;
