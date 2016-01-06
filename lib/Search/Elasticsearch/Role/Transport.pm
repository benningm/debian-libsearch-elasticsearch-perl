package Search::Elasticsearch::Role::Transport;
$Search::Elasticsearch::Role::Transport::VERSION = '2.00';
use Moo::Role;

requires qw(perform_request);

use Try::Tiny;
use Search::Elasticsearch::Util qw(parse_params is_compat);
use namespace::clean;

has 'serializer'       => ( is => 'ro', required => 1 );
has 'logger'           => ( is => 'ro', required => 1 );
has 'send_get_body_as' => ( is => 'ro', default  => 'GET' );
has 'cxn_pool'         => ( is => 'ro', required => 1 );

#===================================
sub BUILD {
#===================================
    my $self = shift;
    my $pool = $self->cxn_pool;
    is_compat( 'cxn_pool', $self, $pool );
    is_compat( 'cxn',      $self, $pool->cxn_factory->cxn_class );
    return $self;
}

#===================================
sub tidy_request {
#===================================
    my ( $self, $params ) = parse_params(@_);
    $params->{method} ||= 'GET';
    $params->{path}   ||= '/';
    $params->{qs}     ||= {};
    $params->{ignore} ||= [];
    my $body = $params->{body};
    return $params unless defined $body;

    $params->{serialize} ||= 'std';
    $params->{data}
        = $params->{serialize} eq 'std'
        ? $self->serializer->encode($body)
        : $self->serializer->encode_bulk($body);

    if ( $params->{method} eq 'GET' ) {
        my $send_as = $self->send_get_body_as;
        if ( $send_as eq 'POST' ) {
            $params->{method} = 'POST';
        }
        elsif ( $send_as eq 'source' ) {
            $params->{qs}{source} = delete $params->{data};
            delete $params->{body};
        }
    }

    $params->{mime_type} ||= $self->serializer->mime_type;
    return $params;

}

1;

#ABSTRACT: Transport role providing interface between the client class and the Elasticsearch cluster

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::Elasticsearch::Role::Transport - Transport role providing interface between the client class and the Elasticsearch cluster

=head1 VERSION

version 2.00

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Elasticsearch BV.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
