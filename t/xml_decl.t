use strict;
use warnings;

use Test::More;
use XML::BindData;

is(
	XML::BindData->bind("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<foo>\xC3\xA9</foo>\n", {}),
	"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<foo>\xC3\xA9</foo>\n",
	'UTF-8 + version declaration preserved'
);

is(
	XML::BindData->bind("<?xml version=\"1.0\" encoding=\"iso-8859-1\"?>\n<foo>\xE9</foo>\n", {}),
	"<?xml version=\"1.0\" encoding=\"iso-8859-1\"?>\n<foo>\xE9</foo>\n",
	"ISO-8859-1 + version declaration preserved"
);

done_testing;
