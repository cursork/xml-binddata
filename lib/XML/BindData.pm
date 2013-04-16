use strict;
use warnings;

package XML::BindData;

use XML::LibXML;

sub bind {
	my ($class, $xml_string, $data) = @_;

	my $xml = XML::LibXML->load_xml(string => $xml_string);
	parse_node($xml->documentElement, $data);

	return $xml->toStringC14N;
}

sub parse_node {
	my ($node, $context) = @_;

	if (my $if_key = _strip_attr($node, 'tmpl-if')) {
		my $unless = $if_key =~ s/^!//;
		my $val    = _get($context, $if_key);
		if (   (!$unless && !$val)
			|| ( $unless &&  $val)) {
			$node->unbindNode;
		}
	}

	if (my $each_key = _strip_attr($node, 'tmpl-each')) {
		my $parent = $node->parentNode;
		$node->unbindNode;

		my $to_add = _get($context, $each_key);
		if (!$to_add || ref $to_add ne 'ARRAY') {
			$to_add = [];
		}

		foreach my $subcontext (@$to_add) {
			my $new = $node->cloneNode(1); # deep clone
			parse_node($new, $subcontext);
			$parent->appendChild($new);
		}
	}

	if (my $binding = _strip_attr($node, 'tmpl-bind')) {
		my $val = _get($context, $binding) || '';
		$node->appendTextNode($val);
	}

	if (my $attr_map = _strip_attr($node, 'tmpl-attr-map')) {
		my @attributes = map { [ split qr/:/ ] } split qr/,/, $attr_map;

		foreach (@attributes) {
			$node->setAttribute($_->[0], _get($context, $_->[1]));
		}
	}

	my @children = grep {
		$_->nodeType eq XML_ELEMENT_NODE
	} $node->childNodes;
	parse_node($_, $context) foreach @children;
}

sub _get {
	my ($context, $key) = @_;

	return $context if $key eq 'this';

	my @parts = split qr/\./, $key;
	foreach (@parts) {
		$context = $context->{$_};
	}
	return $context;
}

sub _strip_attr {
	my ($node, $attr_name) = @_;

	if (my $attributes = $node->attributes) {
		if (my $attr = $attributes->removeNamedItem($attr_name)) {
			return $attr->nodeValue;
		}
	}
}

1;

__END__

=head1 NAME

XML::BindData - Bind data structures into XML

=head1 SYNOPSIS

=head2 XML (indentation added for clarity)

    <?xml version="1.0" encoding="utf-8"?>
    <request>
        <type>add</type>
        <obj>
            <title tmpl-bind="module.title"/>
            <description tmpl-bind="module.description"/>
            <no-show tmpl-if="foo"/>
            <multiple-elems>
                <item tmpl-each="items">
                    <id tmpl-bind="id"/>
                    <name tmpl-bind="name"/>
                </item>
            </multiple-elems>
            <keywords>
                <keyword tmpl-each="keywords" tmpl-bind="this"/>
            </keywords>
            <here>
                <is-a>
                    <nested tmpl-each="nested">
                        <thing tmpl-each="this" tmpl-attr-map="value:this"/>
                    </nested>
                </is-a>
            </here>
        </obj>
    </request>

=head2 Perl

    my $data = {
        module => {
            title => 'XML::BindData',
            description => <<'EOF',
    Yet another way to generate XML for you.
    EOF
        },
        items => [
            { id => 1, name => 'perl' },
            { id => 2, name => 'xml' },
        ],
        keywords => [ qw/ perl xml / ],
        nested => [
            [ qw/1 2 3/ ],
            [ qw/4 5 6/ ],
        ],
    };

    print XML::BindData->bind($source_xml, $data);

=head2 Output (identation added for clarity)

    <request>
      <type>add</type>
      <obj>
        <title>XML::BindData</title>
        <description>Yet another way to generate XML for you.
    </description>
        <multiple-elems>
          <item>
            <id>1</id>
            <name>perl</name>
          </item>
          <item>
            <id>2</id>
            <name>xml</name>
          </item>
        </multiple-elems>
        <keywords>
          <keyword>perl</keyword>
          <keyword>xml</keyword>
        </keywords>
        <here>
          <is-a>
            <nested>
              <thing value="1"></thing>
              <thing value="2"></thing>
              <thing value="3"></thing>
            </nested>
            <nested>
              <thing value="4"></thing>
              <thing value="5"></thing>
              <thing value="6"></thing>
            </nested>
          </is-a>
        </here>
      </obj>
    </request>

=head1 DESCRIPTION

This module provides yet another mechanism through which XML files can be
created from Perl. It does this by reading in a valid XML template, and binding
data directly into the DOM; creating/removing nodes as needs be.

This has the following benefits:

=over

=item 1. The template 'looks like' the XML to be generated.

=item 2. The template is itself valid XML and can be edited as such.

=item 3. The scope of intentionally limited to simple bindings (as opposed to
XSLT which can be arbitrarily complex).

=item 4. It should be possible to use existing, complex, internal data
structures for the binding.

=back

The module is probably I<not> appropriate if you are already happily using
XSLT, Template::Toolkit, etc. for XML generation.

=head1 SUBROUTINES/METHODS

=over

=item XML::BindData->bind($xml_string, \%data)

This forms the entire public API to the module. It will parse the XML and
traverse the resulting tree, binding the information in data.

=back

=head1 DIRECTIVES

These directives may be assigned to nodes in the tree:

=over

=item tmpl-bind="option.name"

Adds text content to the node. If an option is dot.separated, this will split
on the dot and descend into nested hashes.

=item tmpl-each="option"

For the array ref found at 'option', duplicate this node, setting the current
context to each item. An option name of 'this' refers to the current item, so
a common idiom is:

    <foo tmpl-each="nums" tmpl-bind="this"/>

...for the data...

    { nums => [ 1, 2, 3 ] }

...this would return...

    <foo>1</foo><foo>2</foo><foo>3</foo>

=item tmpl-if="bool"

Only show the node if bool is true-ish. Can be negated as C<tmpl-if="!bool">.

=item tmpl-attr-map="attr-name-one:opt1,attr-name-two:opt2"

Bind the value of 'opt1' into the attribute 'attr-name-one'. Multiple
attributes can be assigned at a time, separated by commas.

=back


