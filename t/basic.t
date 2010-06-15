use strict;
use warnings;
use Test::More;

my %opts = map {
    lc($_) => $ENV{"GOOGLE_STORAGE_${_}"};
} qw(ACCESS_KEY SECRET);

unless($opts{access_key} && $opts{secret}) {
    plan skip_all =>
      'Missing $ENV{GOOGLE_STORAGE_ACCESS_KEY} and $ENV{GOOGLE_STORAGE_SECRET}';
}

use_ok 'Google::Storage',
  'Used Google::Storage';

ok my $gs = Google::Storage->new(%opts), 
  'Created new google storage object';

## Test creating customer_headers

use URI;
use HTTP::Date;
use HTTP::Headers;
use String::Util qw(trim);

our $gsurl = URI->new('http://commondatastorage.googleapis.com/');

my $headers = HTTP::Headers->new(
    Date => time2str(time),
    a => 1,
    b => 2,
    'x-goog-meta-test-a' => "a",
    'x-goog-meta-TEST-b' => "b",
    'x-goOG-meta-test-A' => "aa  ",
    'x-Goog-MEta-test-c' => " c",
    'x-gOOg-meta-test-d' => " d ",
    'x-gOOg-meTa-tESt-e' => "a  bc",
#    'x-gOOg-meTa-tESt-f' => "ab\nc",
    
#    'x-gOOg-meTa-tESt-f' => " \na     b  c\nd\n \r\n   \ta\te\n\n\r ",

);

my $request = HTTP::Request->new(GET=>$gsurl, $headers);
my @canonical_headers = qw(Content-MD5 Content-Type Date);

my @headers = (
    $request->method,
    map {$request->header($_) || ''} @canonical_headers
);

my @extension_headers = (
    map {$_ .':'. join(',', map {trim($_)} $request->headers->header($_))}
    grep {$_=~m/^x-goog/}
    sort {$a cmp $b}
    map {lc $_}
    ($request->headers->header_field_names),
);

my $canonical_string = join("\n", (@headers, @extension_headers, '')) . '/';

use Digest::HMAC_SHA1 qw(hmac_sha1);
use MIME::Base64 qw(encode_base64);

my $b64 = encode_base64(hmac_sha1($canonical_string,$opts{secret}), '');

$request->header(Authorization => "GOOG1 $opts{access_key}:$b64");

my $ua = LWP::UserAgent->new(
    keep_alive => 10,
    requests_redirectable => [qw(GET HEAD DELETE PUT)],
);

my $response = $ua->request($request);

use Data::Dump 'dump';
warn  $response->content;
## warn dump $response;
warn dump @headers,@extension_headers;


warn dump $gs->buckets;

done_testing;

__END__


