# XML::BindData

Bind data structures into XML

    cpanm XML::BindData

## SYNOPSIS

### XML (indentation added for clarity)

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

### Perl

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

### Output (indentation added for clarity)

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

## DESCRIPTION

This module provides yet another mechanism through which XML files can be
created from Perl. It does this by reading in a valid XML template, and binding
data directly into the DOM; creating/removing nodes as needs be.

This has the following benefits:

1. The template 'looks like' the XML to be generated.
2. The template is itself valid XML and can be edited as such.
3. The scope is intentionally limited to simple bindings (as opposed to
XSLT which can be arbitrarily complex).
4. It is intended to be possible to use existing, complex, internal data
structures for the binding.

The module is probably _not_ appropriate if you are already happily using
XSLT, Template Toolkit, etc. for XML generation.

## SUBROUTINES/METHODS

- XML::BindData->bind($xml\_string, \\%data)

    This forms the entire public API to the module. It will parse the XML and
    traverse the resulting tree, binding the information in %data.

## DIRECTIVES

These directives may be assigned to nodes in the tree:

- tmpl-bind="option.name"

    Adds text content to the node. If an option is dot.separated, this will split
    on the dot and descend into nested hashes.

- tmpl-each="option"

    For the array ref found at 'option', duplicate this node, setting the current
    context to each item. An option name of 'this' refers to the current item, so
    a common idiom is:

        <foo tmpl-each="nums" tmpl-bind="this"/>

    ...for the data...

        { nums => [ 1, 2, 3 ] }

    ...this would return...

        <foo>1</foo><foo>2</foo><foo>3</foo>

- tmpl-if="bool"

    Only show the node if bool is true-ish. Can be negated as `tmpl-if="!bool"`.

- tmpl-attr-map="attr-name-one:opt1,attr-name-two:opt2"

    Bind the value of 'opt1' into the attribute 'attr-name-one'. Multiple
    attributes can be assigned at a time, separated by commas.


