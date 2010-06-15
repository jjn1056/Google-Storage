package Google::Storage;

use URI;
use Moose;
use XML::Simple;
use LWP::UserAgent;
use HTTP::Headers;
use HTTP::Request;
use HTTP::Date qw(time2str);
use Digest::HMAC_SHA1 qw(hmac_sha1);
use MIME::Base64 qw(encode_base64);
use String::Util qw(crunch trim);
use XML::Bare;
use Method::Signatures::Simple;
use Google::Storage::Bucket;

our $VERSION = "0.01";

has ['access_key', 'secret'] => (is=>'ro', isa=>'Str', required=>1);
has 'gsurl' => (is=>'ro', isa=>'Object', lazy_build=>1);
has 'ua' => (is=>'ro', isa=>'Object', lazy_build=>1);

method _build_gsurl {
    URI->new('http://commondatastorage.googleapis.com/');
}
method _build_ua {
    LWP::UserAgent->new(
        keep_alive => 10,
        requests_redirectable => [qw(GET HEAD DELETE PUT)],
    );
}
method buckets {

    my $headers = HTTP::Headers->new(
        Date => time2str(time),
    );

    my $request = HTTP::Request->new(GET=>$self->gsurl, $headers);

    my @canonical_headers = qw(Content-MD5 Content-Type Date);
    my @headers = (
        $request->method,
        map {$request->header($_) || ''} @canonical_headers
    );

    my $normalize_header = sub {
        my $key = shift @_;
        my @headers = $request->headers->header($key);
        my @folded_headers = map { trim($_) } @headers;
        my $flattend_headers = join ',', @folded_headers;
        return "$key:$flattend_headers";
    };

    my @extension_headers = (
        map { $normalize_header->($_) }
        sort {$a cmp $b}
        grep {$_=~m/^x-goog/}
        map {lc $_}
        ($request->headers->header_field_names),
    );

    my $resource = $self->gsurl->path;
    my $canonical_string = join("\n", (@headers, @extension_headers)) ."\n$resource";
    my $canonical_string_signed = hmac_sha1($canonical_string, $self->secret);
    my $canonical_string_b464 = encode_base64($canonical_string_signed, '');

    $request->header(Authorization => "GOOG1 ".$self->access_key.":$canonical_string_b464");

    my $response = $self->ua->request($request);
    if ($response->is_success) {
        my $parse_tree = XML::Bare->new(text=>$response->decoded_content);
        my $parsed_content = $parse_tree->parse;
        my $buckets = $parsed_content->{ListAllMyBucketsResult}->{Buckets}->{Bucket};
        my @buckets = map { Google::Storage::Bucket->new(
            creation_date => $_->{CreationDate}->{value},
            name => $_->{Name}->{value},
        ) } ref $buckets eq 'ARRAY' ? @$buckets : ($buckets);

        return {
            owner_id => $parsed_content->{ListAllMyBucketsResult}->{Owner}->{ID}->{value},
            owner_displayname => '',
            buckets => \@buckets,
        };

    } else {
        return $response->status_line;
    }
}

=head1 NAME

Google::Storage - Wrapper for Google Storage REST API

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
