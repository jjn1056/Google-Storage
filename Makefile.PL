#!/usr/bin/env perl

use strict;
use warnings;
use inc::Module::Install;

requires (
    'Moose' => '1.07',
    'LWP::UserAgent' => '5.835',
    'HTTP::Date' => '5.831',
    'HTTP::Request' => '5.827',
    'HTTP::Headers' => '5.835',
    'XML::Bare' => '0.45',
    'URI' => '1.54',
    'MIME::Base64' => '3.09',
    'Digest::HMAC_SHA1' => '1.01',
    'String::Util' => '0.11',
);

build_requires (
    'Test::More' => '0.94',
);

all_from 'lib/Google/Storage.pm';
repository 'git://github.com/jjn1056/Google-Storage.git';
auto_install;
WriteAll;

