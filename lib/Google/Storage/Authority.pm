package Google::Storage::Authority;

use Moose;
use Method::Signatures::Simple;
use Digest::HMAC_SHA1 qw(hmac_sha1);
use MIME::Base64 qw(encode_base64);
use String::Util qw(trim);

has ['access_key', 'secret'] => (is=>'ro', isa=>'Str', required=>1);

method sign_request($request) {
    my @canonical_headers = $self->_canonical_headers($request);
    my @extension_headers = $self->_extension_headers($request);
    my $resource = $request->uri->path;

    my $canonical_string = join("\n", @canonical_headers, @extension_headers) . "\n$resource";
    my $signed_string = hmac_sha1($canonical_string, $self->secret);
    my $b64_string = encode_base64($signed_string, '');

    $request->header(Authorization => "GOOG1 ".$self->access_key.":$b64_string");
    return $request;
}

method _canonical_headers($request) {
    return (
        $request->method,
        (map { $request->header($_) || ''}
          qw(Content-MD5 Content-Type Date)),
    );
}

method _extension_headers($request) {
    return (
        map { $self->_normalize_header($request, $_) }
        sort {$a cmp $b}
        grep {$_=~m/^x-goog/}
        map {lc $_}
        ($request->headers->header_field_names),
    );
}

method _normalize_header($request, $header_name) {
    my @headers = $request->headers->header($header_name);
    my @whitespace_folded_headers = map { trim($_) } @headers;
    my $flattend_headers = join ',', @whitespace_folded_headers;
    return "$header_name:$flattend_headers";
}


=head1 NAME

Google::Storage::Authority - Access To Google Storage Buckets and Objects

=head1 SYNOPSIS

    use aliased Google::Storage::Authority;

    my $authority = Authority->new(
        access_key => $google_storage_access_key,
        secret => $google_storage_secret,
    );

    my $signed_request = $authority->sign_request($request);
    my $response = $ua->request($sign_request);
    
=head1 DESCRIPTION

When a Google identity has a Google Storage account, that account has the
ability to create sets of keys for accessing buckets and objects associated
with that account.  Each key set consists of an access key and a secret word.

Please see Google Storage documentation for more.

=head1 ATTRIBUTES

This class defines the following Attributes.

=head2 access_key ($str)

This is a required string that should be the access key you created in your
Google Storage Key Management console.

=head2 secret ($str)

This is a required string that should be the access key you created in your
Google Storage Key Management console.  

=head1 METHODS

This class defines the following Methods.

=head2 sign_request ($request)

Given a L<HTTP::Request>, provide an Authorization header which is a signed
string that Google Storage uses to establish identity and rights.  This returns
a new request object.  Example:

    my $signed_request = $authority->sign_request($request);
    my $response = $ua->request($sign_request);

Please see test cases and L<Google::Storage> for more.

=head1 AUTHOR

John Napiorkowski C< <<jjnapiork@cpan.org>> >

=head1 COPYRIGHT & LICENSE

Copyright 2010, John Napiorkowski

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;


