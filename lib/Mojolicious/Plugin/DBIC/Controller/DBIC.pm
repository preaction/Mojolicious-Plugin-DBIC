package Mojolicious::Plugin::DBIC::Controller::DBIC;
our $VERSION = '0.002';
# ABSTRACT: Build simple views to DBIC data

=head1 SYNOPSIS

    use Mojolicious::Lite;
    plugin DBIC => { schema => ... };
    get '/', {
        controller => 'DBIC',
        action => 'list',
        resultset => 'BlogPosts',
        template => 'blog/list',
    };

=head1 DESCRIPTION

This controller allows for easy working with data from the schema.
Controllers are configured through the stash when setting up the routes.

=head1 SEE ALSO

L<Mojolicious::Plugin::DBIC>

=cut

use Mojo::Base 'Mojolicious::Controller';

=method list

    get '/', {
        controller => 'DBIC',
        action => 'list',
        resultset => 'BlogPosts',
        template => 'blog/list',
    };

List data in a ResultSet.

This method uses the following stash values for configuration:

=over

=item resultset

The L<DBIx::Class::ResultSet> class to list.

=back

This method sets the following stash values for template rendering:

=over

=item resultset

The L<DBIx::Class::ResultSet> object containing the desired objects.

=back

=cut

sub list {
    my ( $c ) = @_;
    my $rs_class = $c->stash( 'resultset' );
    my $rs = $c->schema->resultset( $rs_class );
    return $c->render(
        resultset => $rs,
    );
}

=method get

    get '/blog/:id', {
        controller => 'DBIC',
        action => 'get',
        resultset => 'BlogPosts',
        template => 'blog/get',
    };

Fetch a single result by its ID.

This method uses the following stash values for configuration:

=over

=item resultset

The L<DBIx::Class::ResultSet> class to use.

=item id

The ID to pass to L<DBIx::Class::ResultSet/find>.

=back

This method sets the following stash values for template rendering:

=over

=item row

The L<DBIx::Class::Row> object containing the desired object.

=back

=cut

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
