use strict;
use warnings;

package XML::BindData::Backwards;

use XML::LibXML;

sub unbind {
	my ($class, $xml_with_binds, $data_xml) = @_;

	my $context = {};
	my $with_binds = XML::LibXML->load_xml(string => $xml_with_binds);
	my $data       = XML::LibXML->load_xml(string => $data_xml);
	eval {
		parse_node($with_binds->documentElement, $data->documentElement, $context);
	};
	if ($@ =~ /^Structures must be/) {
		return undef;
	} elsif ($@) {
		die $@;
	}

	return $context;
}

sub parse_node {
	my ($node, $data_node, $context) = @_;

	if (my $if_key = _get_attr($node, 'tmpl-if')) {
		# it can of course be undefined (it's removed from the tree)
		my $bool   = (defined $data_node && $node->nodeName eq $data_node->nodeName)
		             ? 1 : 0;

		if ($if_key =~ s/^!//) {
			# Specifically want 0 and 1, so don't use bang
			$bool = $bool ? 0 : 1;
		}

		_set($context, $if_key, $bool);

		if ($node->nextSibling && $data_node) {
			parse_node($node->nextSibling, $data_node, $context);
		}
		return;
	}

	if ($node->nodeName ne $data_node->nodeName) {
		die 'Structures must be identical for unbinding to work.';
	}

	# TODO - doesn't handle recursively nested arrays!
	if (my $each_key = _get_attr($node, 'tmpl-each', 1)) {
		my $subcontext = [];
		_set($context, $each_key, $subcontext);

		my @collected = _collect_siblings_with_name($data_node);

		foreach my $sub_data_node (@collected) {
			parse_node($node, $sub_data_node, $subcontext);
		}

		# Doesn't make sense to recurse into the children here...
		return;
	}

	if (my $binding = _get_attr($node, 'tmpl-bind')) {
		$context = _set($context, $binding, $data_node->textContent);
	}

	if (my $attr_map = _get_attr($node, 'tmpl-attr-map')) {
		my @attributes = map { [ split qr/:/ ] } split qr/,/, $attr_map;

		foreach (@attributes) {
			my $val = $data_node->getAttribute($_->[0]);
			_set($context, $_->[1], $val);
		}
	}

	my @children = grep {
		$_->nodeType eq XML_ELEMENT_NODE
	} $node->childNodes;

	my @data_children = grep {
		$_->nodeType eq XML_ELEMENT_NODE
	} $data_node->childNodes;

	while(@children) {
		parse_node(shift @children, shift @data_children, $context);
	}
}

sub _set {
	my ($orig_context, $key, $val) = @_;

	my $context = $orig_context;
	my @parts   = split qr/\./, $key;
	my $last    = pop @parts;

	while (@parts) {
		my $temp = {};
		_set_one($context, shift @parts, $temp);
		$context = $temp;
	}

	_set_one($context, $last, $val);

	# We actually want to pop all the way out when dot.notation has been used
	return $orig_context;
}

sub _set_one {
	my ($context, $key, $val) = @_;

	if ($key eq 'this') {
		if (ref $context eq 'ARRAY') {
			push @$context, $val;
			return $context;
		}
	} elsif (ref $context eq 'HASH') {
		$context->{$key} = $val;
		return $context;
	} elsif (ref $context eq 'ARRAY') {
		my $new_context = { $key => $val };
		push @$context, $new_context;
		return $new_context;
	} else {
		warn 'Bad ref seen for context: ' . ref $context;
	}
}

sub _get_attr {
	my ($node, $attr_name, $strip) = @_;

	return unless $node;

	if (my $attributes = $node->attributes) {
		my $attr = $strip ? $attributes->removeNamedItem($attr_name)
		                  : $attributes->getNamedItem($attr_name);
		if ($attr) {
			return $attr->nodeValue;
		}
	}
}

sub _collect_siblings_with_name {
	my ($node) = @_;

	my $name = $node->nodeName;
	my @collected;

	while ($node && $node->nodeName eq $name) {
		push @collected, $node;
		$node = $node->nextSibling;
	}

	$_->unbindNode foreach @collected;

	return @collected;
}

1;

__END__

=head1 NAME

XML::BindData::Backwards - Reverse the binding process

=head1 SYNOPSIS

	my $tmpl_xml = '<foo><bar tmpl-each="bar"><baz tmpl-bind="id"/></bar></foo>';
	my $data_xml = '<foo><bar><baz>1</baz></bar><bar><baz>1</baz></bar></foo>';

	my $data = XML::BindData::Backwards->unbind($tmpl_xml, $data_xml);
	# ==> { bar => [ { id => 1 }, { id => 2 } ] }

=head1 DESCRIPTION

This reverses the process laid out in L<XML::BindData>. This module is a bit of
fun; as such, it should be considered B<pre-ALPHA> in quality. In the unlikely
event, that there is a material benefit in an C<unbind> method, it will likely
be merged into the L<XML::BindData> module proper.

=head1 BUGS AND LIMITATIONS

Currently, this module does not correctly handle nested arrays. To illustrate,
the following example XML is skipped in the test suite:

    <foo>
      <bar tmpl-each="bar">
        <baz tmpl-each="this" tmpl-bind="this"/>
      </bar>
    </foo>
