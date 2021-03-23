package Mojolicious::Plugin::DBIC;
our $VERSION = '0.005';
# ABSTRACT: Mojolicious ♥ DBIx::Class

=head1 SYNOPSIS

    use Mojolicious::Lite;
    plugin DBIC => {
        schema => { 'Local::Schema' => 'dbi:SQLite::memory:' },
    };
    get '/model', {
        controller => 'DBIC',
        action => 'list',
        resultset => 'Model',
        template => 'model/list.html.ep',
    };
    app->start;
    __DATA__
    @@ model/list.html.ep
    % for my $row ( $resultset->all ) {
        <p><%= $row->id %></p>
    % }

=head1 DESCRIPTION

This plugin makes working with L<DBIx::Class> easier in Mojolicious.

=head2 Configuration

Configure your schema in multiple ways:

    # Just DSN
    plugin DBIC => {
        schema => {
            'MySchema' => 'DSN',
        },
    };

    # Arguments to connect()
    plugin DBIC => {
        schema => {
            'MySchema' => [ 'DSN', 'user', 'password', { RaiseError => 1 } ],
        },
    };

    # Connected schema object
    my $schema = MySchema->connect( ... );
    plugin DBIC => {
        schema => $schema,
    };

This plugin can also be configured from the application configuration
file:

    # myapp.conf
    {
        dbic => {
            schema => {
                'MySchema' => 'dbi:SQLite:data.db',
            },
        },
    }

    # myapp.pl
    use Mojolicious::Lite;
    plugin 'Config';
    plugin 'DBIC';

=head2 Controller

This plugin contains a controller to reduce the code needed for simple
database operations. See L<Mojolicious::Plugin::DBIC::Controller::DBIC>.

=head1 SEE ALSO

L<Mojolicious>, L<DBIx::Class>, L<Yancy>

=cut

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Loader qw( load_class );
use Scalar::Util qw( blessed );

sub register {
    my ( $self, $app, $conf ) = @_;
    # XXX Allow multiple schemas?
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

