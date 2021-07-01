package Mojolicious::Plugin::DBIC::Controller::DBIC;
our $VERSION = '0.006';
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

List data in a ResultSet. Returns false if it has rendered a response,
true if dispatch can continue.

This method uses the following stash values for configuration:

=over

=item resultset

The L<DBIx::Class::ResultSet> class to list.

=back

This method sets the following stash values for template rendering:

=over

=item resultset

The L<DBIx::Class::ResultSet> object containing the desired objects.

=item limit

The number of items to show on the page. Defaults to C<10>.

=item page

The page number to show. Defaults to C<1>.

=item order_by

Set the default order for the items. Supports any DBIx::Class
C<order_by> structure.

=back

=head4 Query Params

The following URL query parameters are allowed for this method:

=over

=item $page

Instead of using the C<page> stash value, you can use the C<$page> query
paremeter to set the page.

=item $offset

Instead of using the C<page> stash value, you can use the C<$offset>
query parameter to set the page offset. This is overridden by the
C<$page> query parameter.

=item $limit

Instead of using the C<limit> stash value, you can use the C<$limit>
query parameter to allow users to specify their own page size.

=item $order_by

One or more fields to order by. Can be specified as C<< <name> >> or
C<< asc:<name> >> to sort in ascending order or C<< desc:<field> >>
to sort in descending order.

=cut

sub list {
    my ( $c ) = @_;

    my $limit = $c->param( '$limit' ) // $c->stash->{ limit } // 10;
    my $offset = $c->param( '$page' ) ? ( $c->param( '$page' ) - 1 ) * $limit
        : $c->param( '$offset' ) ? $c->param( '$offset' )
        : ( ( $c->stash->{page} // 1 ) - 1 ) * $limit;
    $c->stash( page => int( $offset / $limit ) + 1 );

    my $opt = {
        rows => $limit,
        offset => $offset,
    };

    if ( my $order_by = $c->param( '$order_by' ) ) {
        $opt->{order_by} = [
            map +{ "-" . ( $_->[1] ? $_->[0] : 'asc' ) => $_->[1] // $_->[0] },
            map +[ split /:/ ],
            split /,/, $order_by
        ];
    }
    elsif ( $order_by = $c->stash( 'order_by' ) ) {
        $opt->{order_by} = $order_by;
    }

    my $rs_class = $c->stash( 'resultset' );
    my $rs = $c->schema->resultset( $rs_class )->search( {}, $opt );
    return $c->stash(
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

Fetch a single result by its ID. If no result is found, renders a not
found error. Returns false if it has rendered a response, true if
dispatch can continue.

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
    if ( !$row ) {
        $c->reply->not_found;
        return;
    }
    return $c->stash(
        row => $row,
    );
}

=method set

    $routes->any( [ 'GET', 'POST' ] => '/:id/edit' )->to(
        'DBIC#set',
        resultset => $resultset_name,
        template => $template_name,
    );

    $routes->any( [ 'GET', 'POST' ] => '/create' )->to(
        'DBIC#set',
        resultset => $resultset_name,
        template => $template_name,
        forward_to => $route_name,
    );

This route creates a new item or updates an existing item in
a collection. If the user is making a C<GET> request, they will simply
be shown the template. If the user is making a C<POST> or C<PUT>
request, the form parameters will be read, and the user will either be
shown the form again with the result of the form submission (success or
failure) or the user will be forwarded to another place.

This method uses the following stash values for configuration:

=over

=item resultset

The resultset to use. Required.

=item id

The ID of the item from the collection. Optional: If not specified, a new
item will be created. Usually part of the route path as a placeholder.

=item template

The name of the template to use. See L<Mojolicious::Guides::Rendering/Renderer>
for how template names are resolved.

=item forward_to

The name of a route to forward the user to on success. Optional. Any
route placeholders that match item field names will be filled in.

    $routes->get( '/:id/:slug' )->name( 'blog.view' );
    $routes->post( '/create' )->to(
        'DBIC#set',
        resultset => 'blog',
        template => 'blog_edit.html.ep',
        forward_to => 'blog.view',
    );

    # { id => 1, slug => 'first-post' }
    # forward_to => '/1/first-post'

Forwarding will not happen for JSON requests.

=item properties

Restrict this route to only setting the given properties. An array
reference of properties to allow. Trying to set additional properties
will result in an error.

B<NOTE:> Unless restricted to certain properties using this
configuration, this method accepts all valid data configured for the
collection. The data being submitted can be more than just the fields
you make available in the form. If you do not want certain data to be
written through this form, you can prevent it by using this.

=back

The following stash values are set by this method:

=over

=item row

The L<DBIx::Class::Row> that is being edited, if the C<id> is given.
Otherwise, the item that was created.

=item error

A scalar containing the exception thrown by the insert/update.

=back

Each field in the item is also set as a param using
L<Mojolicious::Controller/param> so that tag helpers like C<text_field>
will be pre-filled with the values. See
L<Mojolicious::Plugin::TagHelpers> for more information. This also means
that fields can be pre-filled with initial data or new data by using GET
query parameters.

This method is protected by L<Mojolicious's Cross-Site Request Forgery
(CSRF) protection|Mojolicious::Guides::Rendering/Cross-site request
forgery>. CSRF protection prevents other sites from tricking your users
into doing something on your site that they didn't intend, such as
editing or deleting content. You must add a C<< <%= csrf_field %> >> to
your form in order to delete an item successfully. See
L<Mojolicious::Guides::Rendering/Cross-site request forgery>.

Displaying a form could be done as a separate route using the C<dbic#get>
method, but with more code:

    $routes->get( '/:id/edit' )->to(
        'DBIC#get',
        resultset => $resultset_name,
        template => $template_name,
    );
    $routes->post( '/:id/edit' )->to(
        'DBIC#set',
        resultset => $resultset_name,
        template => $template_name,
    );

=cut

sub set {
    my ( $c ) = @_;
    my $rs_class = $c->stash( 'resultset' )
        || die q{"resultset" name not defined in stash};
    my $id = $c->stash( 'id' );

    # Display the form, if requested. This makes the simple case of
    # displaying and managing a form easier with a single route instead
    # of two routes (one to "yancy#get" and one to "yancy#set")
    if ( $c->req->method eq 'GET' ) {
        if ( $id ) {
            my $row = $c->schema->resultset( $rs_class )->find( $id );
            $c->stash( row => $row );
            my @props = $row->result_source->columns;
            for my $key ( @props ) {
                # Mojolicious TagHelpers take current values through the
                # params, but also we allow pre-filling values through the
                # GET query parameters (except for passwords)
                $c->param( $key => $c->param( $key ) // $row->$key );
            }
        }

        $c->respond_to(
            json => {
                status => 400,
                json => {
                    errors => [
                        {
                            message => 'GET request for JSON invalid',
                        },
                    ],
                },
            },
            html => { },
        );
        return;
    }

    if ( $c->accepts( 'html' ) && $c->validation->csrf_protect->has_error( 'csrf_token' ) ) {
        $c->app->log->error( 'CSRF token validation failed' );
        $c->render(
            status => 400,
            row => $id ? $c->schema->resultset( $rs_class )->find( $id ) : undef,
            errors => [
                {
                    message => 'CSRF token invalid.',
                },
            ],
        );
        return;
    }

    my $data = $c->req->params->to_hash;
    delete $data->{csrf_token};
    #; use Data::Dumper;
    #; $c->app->log->debug( Dumper $data );

    my $rs = $c->schema->resultset( $rs_class );
    if ( my $props = $c->stash( 'properties' ) ) {
        $data = {
            map { $_ => $data->{ $_ } }
            grep { exists $data->{ $_ } }
            @$props
        };
    }

    my $row;
    my $update = $id ? 1 : 0;
    if ( $update ) {
        $row = $rs->find( $id );
        eval { $row->update( $data ) };
    }
    else {
        $row = eval { $rs->create( $data ) };
    }

    if ( my $error = $@ ) {
        $c->app->log->error( 'Error in set: ' . $error );
        $c->res->code( 500 );
        $row = $id ? $rs->find( $id ) : undef;
        $c->respond_to(
            json => { json => { error => $error } },
            html => { row => $row, error => $error },
        );
        return;
    }

    return $c->respond_to(
        json => sub {
            $c->stash(
                status => $update ? 200 : 201,
                json => $row->get_inflated_columns,
            );
        },
        html => sub {
            if ( my $route = $c->stash( 'forward_to' ) ) {
                $c->redirect_to( $route, $row->get_inflated_columns );
                return;
            }
            $c->stash( row => $row );
        },
    );
}

=method delete

    $routes->any( [ 'GET', 'POST' ], '/delete/:id' )->to(
        'DBIC#delete',
        resultset => $resultset_name,
        template => $template_name,
        forward_to => $route_name,
    );

This route deletes a row from a ResultSet. If the user is making
a C<GET> request, they will simply be shown the template (which can be
used to confirm the delete). If the user is making a C<POST> or C<DELETE>
request, the row will be deleted and the user will either be shown the
form again with the result of the form submission (success or failure)
or the user will be forwarded to another place.

This method uses the following stash values for configuration:

=over

=item resultset

The ResultSet class to use. Required.

=item id

The ID of the row from the table. Required. Usually part of the
route path as a placeholder.

=item template

The name of the template to use. See L<Mojolicious::Guides::Rendering/Renderer>
for how template names are resolved.

=item forward_to

The name of a route to forward the user to on success. Optional.
Forwarding will not happen for JSON requests.

=back

The following stash values are set by this method:

=over

=item row

The row that will be deleted. If displaying the form again after the row
is deleted, this will be C<undef>.

=back

This method is protected by L<Mojolicious's Cross-Site Request Forgery
(CSRF) protection|Mojolicious::Guides::Rendering/Cross-site request
forgery>. CSRF protection prevents other sites from tricking your users
into doing something on your site that they didn't intend, such as
editing or deleting content. You must add a C<< <%= csrf_field %> >> to
your form in order to delete an item successfully. See
L<Mojolicious::Guides::Rendering/Cross-site request forgery>.

=cut

sub delete {
    my ( $c ) = @_;
    my $rs_class = $c->stash( 'resultset' );
    my $id = $c->stash( 'id' );
    my $rs = $c->schema->resultset( $rs_class );
    my $row = $rs->find( $id );

    # Display the form, if requested. This makes it easy to display
    # a confirmation page in a single route.
    if ( $c->req->method eq 'GET' ) {
        $c->respond_to(
            json => {
                status => 400,
                json => {
                    errors => [
                        {
                            message => 'GET request for JSON invalid',
                        },
                    ],
                },
            },
            html => { row => $row },
        );
        return;
    }

    if ( $c->accepts( 'html' ) && $c->validation->csrf_protect->has_error( 'csrf_token' ) ) {
        $c->app->log->error( 'CSRF token validation failed' );
        $c->render(
            status => 400,
            row => $row,
            errors => [
                {
                    message => 'CSRF token invalid.',
                },
            ],
        );
        return;
    }

    $row->delete;

    return $c->respond_to(
        json => sub {
            $c->rendered( 204 );
            return;
        },
        html => sub {
            if ( my $route = $c->stash( 'forward_to' ) ) {
                $c->redirect_to( $route );
                return;
            }
        },
    );
}

1;
