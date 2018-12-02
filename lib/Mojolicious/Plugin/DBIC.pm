package Mojolicious::Plugin::DBIC;
our $VERSION = '0.001';
# ABSTRACT: Write a sentence about what it does

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

=cut

use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ( $self, $app, $conf ) = @_;
    # XXX Allow multiple schemas
    # XXX Allow configuring schema connect() method
    $app->helper( schema => sub { $conf->{schema} } );
    push @{ $app->routes->namespaces }, 'Mojolicious::Plugin::DBIC::Controller';
}

1;

