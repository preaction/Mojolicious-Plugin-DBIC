package Local::Controller::Extended;
use Mojo::Base 'Mojolicious::Plugin::DBIC::Controller::DBIC';

sub list {
    my ( $c ) = @_;
    $c->SUPER::list();
    $c->stash( extended => 'Extended' );
}

sub get {
    my ( $c ) = @_;
    $c->SUPER::get();
    $c->stash( extended => 'Extended' );
}

1;
