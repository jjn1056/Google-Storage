package Google::Storage::Request;

use URI;
use Moose;
use LWP::UserAgent;
use HTTP::Date;
use HTTP::Headers;
use HTTP::Request;
use Digest::HMAC_SHA1;
use MIME::Base64 qw(encode_base64);
use Method::Signatures::Simple;


our $VERSION = "0.01";
our $gsurl = URI->new('http://commondatastorage.googleapis.com/');

has ['access_key', 'secret'] => (is=>'ro', isa=>'Str', required=>1);
has 'ua' => (is=>'ro', isa=>'Object', lazy_build=>1);

method _build_ua {
    return LWP::UserAgent->new(
        keep_alive => 10,
        requests_redirectable => [qw(GET HEAD DELETE PUT)],
    );
}

method buckets {

    my $headers = HTTP::Headers->new(
        Date => time2str(time),
    );

    my $request = HTTP::Request->new(GET=>$gsurl, $headers);

use Data::Dump 'dump';
warn dump $request;

warn $request->headers;

    my $canonical_headers = join("\n", ($request->method, map {$request->header($_) || ''} qw(Content-MD5 Content-Type Date) )) . "\n";

warn $canonical_headers;

    my $response = $self->ua->request($request);
    if ($response->is_success) {
        return $response->decoded_content;
    } else {
        return $response;
    }
}



## Authorization => sprintf("GOOG1 %s:%s", $self->access_key, $self->secret),



=head1 NAME

Google::Storage - Wrapper for Google Storage Cloud API

=head2 SYNOPSIS

    use Google::Storage;
    
TBD

=head2 DESCRIPTION

TBD

=head1 SEE ALSO

The following modules or resources may be of interest.

L<Moose>, L<MooseX::Types>, L<Amazon::S3>, L<Net::Amazon::S3>

=head1 AUTHOR

John Napiorkowski C< <<jjnapiork@cpan.org>> >

=head1 COPYRIGHT & LICENSE

Copyright 2010, John Napiorkowski <jjnapiork@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
