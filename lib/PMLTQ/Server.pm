package PMLTQ::Server;
use Mojo::Base 'Mojolicious';

use Mango;
use Mango::BSON 'bson_oid';
use Lingua::EN::Inflect 1.895 qw/PL/;
use PMLTQ::Server::Model;

has db => sub { state $mango = Mango->new($ENV{PMLTQ_SERVER_TESTDB} || shift->config->{mongo_uri}) };

has mandel => sub {
  state $mandel = PMLTQ::Server::Model->new(
    storage => shift->db,
    namespaces => [qw/PMLTQ::Server::Model/]
  );
};

# This method will run once at server start
sub startup {
  my $self = shift;

  $self->plugin('Config' => {
    file => $self->home->rel_file('config/pmltq_server.conf')
  });
  $self->plugin('PMLTQ::Server::Helpers');
  $self->plugin('Bootstrap3');
  $self->plugin(Charset => {charset => 'utf8'});
  $self->plugin(Authentication => {
    autoload_user => 0,
    session_key   => 'auth_data',
    our_stash_key => 'auth',
    load_user     => sub {
      my ($app, $user_id) = @_;
      my $user = $app->mandel->collection('user')->search({_id => bson_oid($user_id)})->single;
      return $user;
    },
    validate_user => sub {
      my ($app, $username, $password, $extradata) = @_;

      my $user_id = shift @{$app->mandel->collection('user')->search({
        username => $username||'',
        password => $password||'',
      })->distinct('_id')};
      return defined $user_id ? "$user_id" : undef;
    }
  });
  $self->plugin(Authorization => {
    has_priv   => sub {
      my ($app, $privilege, $extradata) = @_;
      my $user = $app->current_user;
      return 0 unless $user;
      return $user->has_permission($privilege) || $user->has_permission('admin');
    },
    is_role    => sub { print STDERR 'TODO: is_role\n'; },
    user_privs => sub { print STDERR 'TODO: user_privs\n'; },
    user_role  => sub { print STDERR 'TODO: user_role\n'; },
  });

  $self->add_resource_shortcut();

  # Fake PUT and DELETE methods
  $self->hook(before_dispatch => sub {
    my $c = shift;
    return unless my $method = $c->req->params->param('_method');
    $c->req->method($method);
  });

  # Show log in STDERR
  $self->log->handle(\*STDERR);

  # Setup all helpers
  # $self->setup_helpers(); ###  moved to PMLTQ::Server::Helpers

  # Router
  my $r = $self->routes;

  $r->any('/' => sub {
    my $c = shift;
    unless ($c->is_user_authenticated) {
      $c->redirect_to($c->url_for('auth'));
      return;
    }
    $c->redirect_to($c->url_for('admin_welcome'));
  });

  # Autheticate routes
  my $auth = $r->route('/auth')->to(controller => 'Auth');
  $auth->any([qw/GET POST/])->to(action => 'index')->name('auth_login');
  $auth->get('/logout')->to(action => 'pmltq_logout')->name('auth_logout');

  my $admin = $r->route('/admin')->over(authenticated => 1, has_priv => 'admin')->to(controller => 'Admin');
  $admin->get->to(action => 'welcome')->name('admin_welcome');
  $admin->resource('user', controller => 'Admin::User');
  $admin->resource('treebank', controller => 'Admin::Treebank');

  my $profile = $r->get('/profile')->over(authenticated => 1)->to('Profile#index');
  $profile->any([qw/GET POST/] => 'update')->over(has_priv => 'selfupdate')->to('Profile#update');

  # $r->get('/admin/user/test')       ->over(authenticated => 1, has_priv => 'admin')     ->to('Admin#testuserexist');
  # $r->get('/admin/user/list')       ->over(authenticated => 1, has_priv => 'admin')     ->to('Admin#listuser');
  # $r->post('/admin/user/add')       ->over(authenticated => 1, has_priv => 'admin')     ->to('Admin#adduser');
  # $r->get('/admin/user/add')        ->over(authenticated => 1, has_priv => 'admin')     ->to('Admin#adduser_form');
  # $r->get('/admin/user/delete')     ->over(authenticated => 1, has_priv => 'admin')     ->to('Admin#deluser');
  # $r->post('/admin/user/update')    ->over(authenticated => 1, has_priv => 'admin')     ->to('Admin#updateuser');
  # $r->get('/admin/user/update')     ->over(authenticated => 1, has_priv => 'admin')     ->to('Admin#updateuser_form');

  # $r->post('/profile/selfupdate')->over(authenticated => 1, has_priv => 'selfupdate')->to('Profile#update');
  # $r->get('/profile/selfupdate') ->over(authenticated => 1, has_priv => 'selfupdate')->to('Admin#update_form');
  # $r->get('/profile')            ->over(authenticated => 1)                          ->to('Profile#index');

  # $r->get('/admin/treebank/list')    ->over(authenticated => 1, has_priv => 'admin')->to('Admin#listtreebank');
  # $r->post('/admin/treebank/add')    ->over(authenticated => 1, has_priv => 'admin')->to('Admin#addtreebank');
  # $r->get('/admin/treebank/add')     ->over(authenticated => 1, has_priv => 'admin')->to('Admin#addtreebank_form');
  # $r->get('/admin/treebank/delete')  ->over(authenticated => 1, has_priv => 'admin')->to('Admin#deltreebank');
  # $r->post('/admin/treebank/update') ->over(authenticated => 1, has_priv => 'admin')->to('Admin#updatetreebank');
  # $r->get('/admin/treebank/update')  ->over(authenticated => 1, has_priv => 'admin')->to('Admin#updatetreebank_form');

  my $treebank = $r->bridge('/:treebank')->
    name('treebank')->to(controller => 'Treebank', action => 'initialize');
  $treebank->get ('metadata')->to('#metadata');
  $treebank->post('suggest')->to('#suggest');
  $treebank->get ('history', 'treebank_history')->to(controller => 'History', action => 'list');
  $treebank->post('query')->to(controller => 'Query', action => 'query');
  $treebank->post('query/svg', 'query_svg')->to(controller => 'Query', action => 'query_svg');
  $treebank->post('svg')->to(controller => 'Query', action => 'result_svg');
}

sub add_resource_shortcut {
  shift->routes->add_shortcut(
    resource => sub {
      my $r = shift;
      my $name = shift;
      my $params = { @_ ? (ref $_[0] ? %{ $_[0] } : @_) : () };

      my $plural = PL($name, 10);
      my $controller = $params->{controller} || "$name#";

      # Generate "/$name" route, handled by controller $name
      my $resource = $r->route("/$plural")->to(controller => $controller);

      # GET requests - lists the collection of this resource
      $resource->get->to(action => 'list')->name("list_$plural");

      # POST requests - creates a new resource
      $resource->post->to(action => 'create')->name("create_$name");

      # New form
      $r->get("/$name/new")->to(controller => $controller, action => "new_$name")->name("new_$name");

      # Generate "/$name/:id" route, also handled by controller $name

      # resource routes might be chained, so we need to define an
      # individual id and pass its name to the controller (idname)
      $resource = $r->bridge("/$name/:id", 'id' => qr/\d+/)->
        to(controller => $controller, action => "find_$name", "${name}_id" => 'id');

      # GET requests - lists a single resource
      $resource->get->to(controller => $controller, action => 'show')->name("show_$name");

      # DELETE requests - deletes a resource
      $resource->delete->to(controller => $controller, action => 'remove')->name("delete_$name");

      # PUT requests - updates a resource
      $resource->put->to(controller => $controller, action => 'update')->name("update_$name");

      # return "/$name/:id" route so that potential child routes make sense
      return $resource;
    }
  );
}
1;
