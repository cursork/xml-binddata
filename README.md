XML::BindData
=============

An alternative approach to XML generation in Perl. Binds Perl data structures
into XML documents.

## Example

### XML (indentation added for clarity)

```xml
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
```

### Perl

```perl
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
```

### Output (indentation added for clarity)

```xml
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
```
