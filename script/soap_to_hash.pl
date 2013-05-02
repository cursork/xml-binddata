use strict;
use warnings;

use XML::BindData;

use JSON::XS 'encode_json';

my $h = XML::BindData->to_hash(<<'EOF');
<?xml version="1.0"?>
<soap:Envelope
xmlns:soap="http://www.w3.org/2001/12/soap-envelope"
soap:encodingStyle="http://www.w3.org/2001/12/soap-encoding">

<soap:Body xmlns:m="http://www.example.org/stock">
  <m:GetStockPrice>
    <m:StockName tmpl-bind="stock.price" tmpl-attr-map="foo:bar">IBM</m:StockName>
  </m:GetStockPrice>
</soap:Body>

</soap:Envelope> 
EOF

print Data::Dumper->Dump([$h]), "\n";

print encode_json($h);
