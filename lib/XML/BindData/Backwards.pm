use strict;
use warnings;

package XML::BindData::Backwards;

use XML::LibXML;

sub unbind {
	my ($class, $xml_with_binds, $data_xml) = @_;

	my $context = {};
	my $with_binds = XML::LibXML->load_xml(string => $xml_with_binds);
	my $data       = XML::LibXML->load_xml(string => $data_xml);
	parse_node($with_binds->documentElement, $data->documentElement, $context);

	return $context;
}

sub parse_node {
	my ($node, $data_node, $context) = @_;

	if ($node->nodeName ne $data_node->nodeName) {
		die 'Structures must be identical for unbinding to work.';
	}

#	if (my $if_key = _strip_attr($node, 'tmpl-if')) {
#		my $unless = $if_key =~ s/^!//;
#		my $bool    = $node->textContent;
#		$bool = !$bool if $unless;
#
#		return if !$bool;
#	}
#
#	if (my $each_key = _strip_attr($node, 'tmpl-each')) {
#		my $subcontext = _set($context, $each_key, []);
#
#		my @child_nodes = ($node->childNodes || ());
#		foreach my $subnode (@child_nodes) {
#			parse_node($subnode, $subcontext);
#		}
#	}

	if (my $binding = _strip_attr($node, 'tmpl-bind')) {
		_set($context, $binding, $data_node->textContent);
	}

#	if (my $attr_map = _strip_attr($node, 'tmpl-attr-map')) {
#		my @attributes = map { [ split qr/:/ ] } split qr/,/, $attr_map;
#
#		foreach (@attributes) {
#			$node->setAttribute($_->[0], _get($context, $_->[1]));
#		}
#	}

	my @children = grep {
		$_->nodeType eq XML_ELEMENT_NODE
	} $node->childNodes;

	my @data_children = grep {
		$_->nodeType eq XML_ELEMENT_NODE
	} $data_node->childNodes;

	while(@children && @data_children) {
		parse_node(shift @children, shift @data_children, $context);
	}
}

sub _set {
	my ($context, $key, $val) = @_;
	if ($key eq 'this') {
		return $context; # can't actually set val
	}
	$context->{$key} = $val;
	return $context->{$key};
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
