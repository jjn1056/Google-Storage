package Google::Storage::Service;

use Moose;
use Method::Signatures::Simple;
use Google::Storage::Authority;

use URI;
use LWP::UserAgent;

our $url = URI->new('http://commondatastorage.googleapis.com/'),
our $ua = LWP::UserAgent->new(),

has 'authority' => (
    is=>'bare', 
    isa=>'Google::Storage::Authority',
    required=>1, 
    handles=>['sign_request'],
);

method get {

    ## TODO this bit probably needs to be broken out
    use HTTP::Date;
    use HTTP::Request;
    use XML::Bare qw(xmlin);

    my $request = HTTP::Request->new(GET=>$url, [Date=>time2str(time)]);
    my $response = $ua->request($self->sign_request($request));

    if ($response->is_success) {
        return xmlin($response->decoded_content);
    } else {
        return $response->status_line; ## TODO, this blows
    } 
}

=head1 NAME

Google::Storage::Service - Service Request Method 

=head1 SYNOPSIS

    use aliased Google::Storage::Service;

    my $service = Authority->new(
        authority => $authority, 
    );

    my $buckets_info = $service->list_all_my_buckets;
    
=head1 DESCRIPTION

"Lists all of the buckets that are owned by the requester." - From the main
Google Storage Documentation.

=head1 ATTRIBUTES

This class defines the following Attributes.

=head2 authority ($authority_object)

This is a L<Google::Storage::Authority> object which provides the ability to 
connect to Google Storage and sign requests.  This is a required attribute.

=head1 METHODS

This class defines the following Methods.

=head2 get

Returns a data structure (TBD) representing information about Bucket ownership,
and other bucket meta data.

=head1 AUTHOR

John Napiorkowski C< <<jjnapiork@cpan.org>> >

=head1 COPYRIGHT & LICENSE

Copyright 2010, John Napiorkowski

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;


