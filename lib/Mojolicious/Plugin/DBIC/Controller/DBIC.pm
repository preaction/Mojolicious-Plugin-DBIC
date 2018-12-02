package Mojolicious::Plugin::DBIC::Controller::DBIC;
use Mojo::Base 'Mojolicious::Controller';

sub list {
    my ( $c ) = @_;
    my $rs_class = $c->stash( 'resultset' );
    my $rs = $c->schema->resultset( $rs_class );
    return $c->render(
        resultset => $rs,
    );
}

sub get {
    my ( $c ) = @_;
    my $rs_class = $c->stash( 'resultset' );
    my $id = $c->stash( 'id' );
    my $rs = $c->schema->resultset( $rs_class );
    my $row = $rs->find( $id );
    return $c->render(
        row => $row,
    );
}

1;
