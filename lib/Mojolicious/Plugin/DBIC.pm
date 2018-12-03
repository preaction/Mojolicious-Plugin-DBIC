package Mojolicious::Plugin::DBIC;
our $VERSION = '0.001';
# ABSTRACT: Write a sentence about what it does

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

=cut

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Loader qw( load_class );
use Scalar::Util qw( blessed );

sub register {
    my ( $self, $app, $conf ) = @_;
    # XXX Allow multiple schemas
    my $schema_conf = $conf->{schema};
    if ( !$schema_conf && $app->can( 'config' ) ) {
        $schema_conf = $app->config->{dbic}{schema};
    }
    $app->helper( schema => sub {
        state $schema = _load_schema( $schema_conf );
        return $schema;
    } );
    push @{ $app->routes->namespaces }, 'Mojolicious::Plugin::DBIC::Controller';
}

sub _load_schema {
    my ( $conf ) = @_;
    if ( blessed $conf && $conf->isa( 'DBIx::Class::Schema' ) ) {
        return $conf;
    }
    elsif ( ref $conf eq 'HASH' ) {
        my ( $class, $args ) = %{ $conf };
        if ( my $e = load_class( $class ) ) {
            die sprintf 'Unable to load schema class %s: %s',
                $class, $e;
        }
        return $class->connect( ref $args eq 'ARRAY' ? @$args : $args );
    }
    die sprintf "Unknown DBIC schema config. Must be schema object or HASH, not %s",
        ref $conf;
}

1;

