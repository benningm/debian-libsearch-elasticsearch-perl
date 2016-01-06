package Search::Elasticsearch::Role::Client::Direct::Main;
$Search::Elasticsearch::Role::Client::Direct::Main::VERSION = '2.00';
use Moo::Role;
requires '_namespace';

use Search::Elasticsearch::Util qw(parse_params load_plugin is_compat);

has 'cluster'             => ( is => 'lazy', init_arg => undef );
has 'nodes'               => ( is => 'lazy', init_arg => undef );
has 'indices'             => ( is => 'lazy', init_arg => undef );
has 'snapshot'            => ( is => 'lazy', init_arg => undef );
has 'cat'                 => ( is => 'lazy', init_arg => undef );
has 'bulk_helper_class'   => ( is => 'ro',   default  => 'Bulk' );
has 'scroll_helper_class' => ( is => 'ro',   default  => 'Scroll' );
has '_bulk_class'         => ( is => 'lazy' );
has '_scroll_class'       => ( is => 'lazy' );

#===================================
sub create {
#===================================
    my ( $self, $params ) = parse_params(@_);
    my $defn = $self->api->{index};
    $params->{op_type} = 'create';
    $self->perform_request( { %$defn, name => 'create' }, $params );
}

#===================================
sub _build__bulk_class {
#===================================
    my $self = shift;
    $self->_build_helper( 'bulk', $self->bulk_helper_class );
}

#===================================
sub _build__scroll_class {
#===================================
    my $self = shift;
    $self->_build_helper( 'scroll', $self->scroll_helper_class );
}

#===================================
sub _build_helper {
#===================================
    my ( $self, $name, $sub_class ) = @_;
    my $class = load_plugin( 'Search::Elasticsearch', $sub_class );
    is_compat( $name . '_helper_class', $self->transport, $class );
    return $class;
}

#===================================
sub bulk_helper {
#===================================
    my ( $self, $params ) = parse_params(@_);
    $params->{es} ||= $self;
    $self->_bulk_class->new($params);
}

#===================================
sub scroll_helper {
#===================================
    my ( $self, $params ) = parse_params(@_);
    $params->{es} ||= $self;
    $self->_scroll_class->new($params);
}

#===================================
sub _build_cluster  { shift->_build_namespace('Cluster') }
sub _build_nodes    { shift->_build_namespace('Nodes') }
sub _build_indices  { shift->_build_namespace('Indices') }
sub _build_snapshot { shift->_build_namespace('Snapshot') }
sub _build_cat      { shift->_build_namespace('Cat') }
#===================================

#===================================
sub _build_namespace {
#===================================
    my ( $self, $ns ) = @_;
    my $class = load_plugin( $self->_namespace, [$ns] );
    return $class->new(
        {   transport => $self->transport,
            logger    => $self->logger
        }
    );
}

1;

=pod

=encoding UTF-8

=head1 NAME

Search::Elasticsearch::Role::Client::Direct::Main - Attributes and methods used by the top-level Direct::Client

=head1 VERSION

version 2.00

=head1 DESCRIPTION

Contains attributes and builders used to load client namespaces and helpers
such as C<cluster()>, C<nodes()>, C<bulk_helper()> etc used by the
top-level Direct::Client classes.

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Elasticsearch BV.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

__END__

# ABSTRACT: Attributes and methods used by the top-level Direct::Client

