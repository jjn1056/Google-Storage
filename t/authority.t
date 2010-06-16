use strict;
use warnings;

use URI;
use HTTP::Date;
use HTTP::Headers;
use Test::More;
use LWP::UserAgent;

my %opts = map {
    lc($_) => $ENV{"GOOGLE_STORAGE_${_}"};
} qw(ACCESS_KEY SECRET);

unless($opts{access_key} && $opts{secret}) {
    plan skip_all =>
      'Missing $ENV{GOOGLE_STORAGE_ACCESS_KEY} and $ENV{GOOGLE_STORAGE_SECRET}';
}

use_ok 'Google::Storage::Authority',
  'Used Google::Storage::Authority';

ok my $authority = Google::Storage::Authority->new(%opts), 
  'Created Authority object';

ok my $url = URI->new('http://commondatastorage.googleapis.com/'),
  'Created resource url';

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
);

my $request = HTTP::Request->new(GET=>$url, $headers);

ok my $signed_request = $authority->sign_request($request),
  'Got a signed request';

ok my $ua = LWP::UserAgent->new(),
  'Created a user agent';

ok my $response = $ua->request($signed_request),
  'Got a response object';

ok $response->is_success,
  'Got a good response from google storage';

done_testing;

