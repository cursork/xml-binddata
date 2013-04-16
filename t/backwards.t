use strict;
use warnings;

use Test::More;

use_ok 'XML::BindData::Backwards';

my $tests = [
	[
		'<foo tmpl-bind="foo"/>', '<foo>bar</foo>',
		 { foo => 'bar' }, 'Single binding'
	],

	[
		'<root><foo tmpl-bind="foo"/><bar tmpl-bind="bar"/><baz tmpl-bind="baz"/></root>',
		'<root><foo>1</foo><bar>2</bar><baz>3</baz></root>',
		{ foo => '1', bar => '2', baz => '3' }, 'Multiple bindings',
	]
];

foreach my $t (@$tests) {
	my ($source_xml, $data, $output, $msg) = @$t;
	is_deeply(XML::BindData::Backwards->unbind($source_xml, $data), $output, $msg);
}

done_testing;
