package Google::Storage::Bucket;

use Moose;
use Method::Signatures::Simple;
use MooseX::Types::DateTime qw(DateTime);
use MooseX::Types::Moose qw(Str);

coerce DateTime,
from Str,
via { $_ };

has 'name' => (is=>'ro', isa=>'Str', require=>1);
has 'creation_date' => (is=>'ro', isa=>DateTime, require=>1, coerce=>1);

=head1 NAME

Google::Storage::Bucket - One bucket in your Google Storage

=head2 SYNOPSIS
    
TBD

=head2 DESCRIPTION

TBD

=head1 AUTHOR

John Napiorkowski C< <<jjnapiork@cpan.org>> >

=head1 COPYRIGHT & LICENSE

Copyright 2010, John Napiorkowski <jjnapiork@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
