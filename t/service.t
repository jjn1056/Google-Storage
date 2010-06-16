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

use_ok 'Google::Storage::Authority',
  'Used Google::Storage::Authority';

ok my $authority = Google::Storage::Authority->new(%opts), 
  'Created Authority object';

use_ok 'Google::Storage::Service',
  'Used Google::Storage::Service';

ok my $service = Google::Storage::Service->new(authority=>$authority), 
  'Created Service object';

ok ref($service->get),
  'got something from the bucket list';

done_testing;

