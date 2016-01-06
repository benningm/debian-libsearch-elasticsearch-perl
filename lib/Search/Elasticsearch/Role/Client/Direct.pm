package Search::Elasticsearch::Role::Client::Direct;
$Search::Elasticsearch::Role::Client::Direct::VERSION = '2.00';
use Moo::Role;
with 'Search::Elasticsearch::Role::Client';
use Search::Elasticsearch::Util::API::Path qw(path_handler);
use Try::Tiny;
use Package::Stash 0.34 ();
use namespace::clean;

#===================================
sub parse_request {
#===================================
    my $self   = shift;
    my $defn   = shift || {};
    my $params = { ref $_[0] ? %{ shift() } : @_ };

    my $request;
    try {
        $request = {
            ignore    => delete $params->{ignore} || [],
            method    => $defn->{method}          || 'GET',
            serialize => $defn->{serialize}       || 'std',
            path => $self->_parse_path( $defn,              $params ),
            body => $self->_parse_body( $defn->{body},      $params ),
            qs   => $self->_parse_qs( $defn->{qs_handlers}, $params ),
        };
    }
    catch {
        chomp $_;
        my $name = $defn->{name} || '<unknown method>';
        $self->logger->throw_error( 'Param',
                  "$_ in ($name) request. "
                . "See docs at: http://www.elastic.co/guide/en/elasticsearch/reference/current/"
                . $defn->{doc}
                . '.html' );
    };
    return $request;
}

#===================================
sub _parse_path {
#===================================
    my ( $self, $defn, $params ) = @_;
    return delete $params->{path}
        if $params->{path};
    path_handler( $defn, $params );
}

#===================================
sub _parse_body {
#===================================
    my ( $self, $defn, $params ) = @_;
    if ( defined $defn ) {
        die("Missing required param (body)\n")
            if $defn->{required} && !$params->{body};
        return delete $params->{body};
    }
    die("Unknown param (body)\n") if $params->{body};
    return undef;
}

#===================================
sub _parse_qs {
#===================================
    my ( $self, $handlers, $params ) = @_;
    die "No (qs_handlers) defined\n" unless $handlers;
    my %qs;

    if ( my $raw = delete $params->{params} ) {
        die("Arg (params) shoud be a hashref\n")
            unless ref $raw eq 'HASH';
        %qs = %$raw;
    }

    for my $key ( keys %$params ) {
        my $key_defn = $handlers->{$key}
            or die("Unknown param ($key)\n");
        my $handler = $key_defn->{handler}
            or die "No (handler) defined for ($key)\n";
        $qs{$key} = $handler->( delete $params->{$key} );
    }
    return \%qs;
}

#===================================
sub _install_api {
#===================================
    my ( $class, $group ) = @_;
    my $defns = $class->api;
    my $stash = Package::Stash->new($class);

    my $group_qr = $group ? qr/$group\./ : qr//;
    for my $action ( keys %$defns ) {
        my ($name) = ( $action =~ /^$group_qr([^.]+)$/ )
            or next;
        next if $stash->has_symbol( '&' . $name );

        my %defn = ( name => $name, %{ $defns->{$action} } );
        $stash->add_symbol(
            '&' . $name => sub {
                shift->perform_request( \%defn, @_ );
            }
        );
    }
}

1;

# ABSTRACT: Request parsing for Direct clients

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::Elasticsearch::Role::Client::Direct - Request parsing for Direct clients

=head1 VERSION

version 2.00

=head1 DESCRIPTION

This role provides the single C<parse_request()> method for classes
which need to parse an API definition from L<Search::Elasticsearch::Role::API>
and convert it into a request which can be passed to
L<Search::Elasticsearch::Transport/perform_request()>.

=head1 METHODS

=head2 C<perform_request()>

    $request = $client->parse_request(\%defn,\%params);

The C<%defn> is a definition returned by L<Search::Elasticsearch::Role::API/api()>
with an extra key C<name> which should be the name of the method that
was called on the client.  For instance if the user calls C<< $client->search >>,
then the C<name> should be C<"search">.

C<parse_request()> will turn the parameters that have been passed in into
a C<path> (via L<Search::Elasticsearch::Util::API::Path/path_init()>), a query-string
hash (via L<Search::Elasticsearch::Util::API::QS/qs_init>) and will through a
C<body> value directly.

B<NOTE:> If a C<path> key is specified in the C<%params> then it will be used
directly, instead of trying to build path from the path template.  Similarly,
if a C<params> key is specified in the C<%params>, then it will be used
as a basis for the query string hash.  For instance:

    $client->perform_request(
        {
            method => 'GET',
            name   => 'new_method'
        },
        {
            path   => '/new/method',
            params => { foo => 'bar' },
            body   => \%body
        }
    );

This makes it easy to add support for custom plugins or new functionality
not yet supported by the released client.

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Elasticsearch BV.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
