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
ok( defined $response, 'defined response');
ok( defined $response->content, 'defined response content');
ok( $response->content =~ /^\s*\<\?xml/, 'response content starts with <?xml');
ok( $response->content =~ /ListAllMyBucketsResult/, 'response content contains ListAllMyBucketsResult');

use Data::Dump 'dump';
diag("\$response->content:\n", $response->content);
## diag("\$response:\n",dump($response));
diag("\@headers\n", dump(\@headers));
diag("\@extension_headers:", dump(\@extension_headers));
diag("\@buckets:\n", dump($gs->buckets));

my $buckets = $gs->buckets;
ok ( defined $buckets, '$gs->buckets defined' );
ok ( defined $buckets->{buckets}, '$buckets->{buckets} defined' );
ok ( ref $buckets->{buckets} eq 'ARRAY', '$buckets->{buckets} is an arrayref');
ok ( length $buckets->{ownerid}, 'has an ownerid');

# next tests are to be ran only if the user has buckets
if ( !@{ $buckets->{buckets} } ) {
    done_testing();
    exit 0;
}

diag("User has buckets, doing some additional tests...");

my @buckets = @{ $buckets->{buckets} };
if ( @buckets ) {
    for my $bucket ( @buckets ) {
        is ( ref $bucket, 'Google::Storage::Bucket' );
    }
}

done_testing;

