package PMLTQ::Server;
use Mojo::Base 'Mojolicious';

use Mango;
use Mango::BSON 'bson_oid';
use Lingua::EN::Inflect 1.895 qw/PL/;
use Treex::PML;
use PMLTQ;
use PMLTQ::Server::Model;
use PMLTQ::Server::Validation 'check_password';
use File::Spec;

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

  # Setup resources directory
  Treex::PML::AddResourcePathAsFirst(PMLTQ->resources_dir);

  $self->plugin('PMLTQ::Server::MultipleFileConfig' => {
    dir => $self->home->rel_file('config'),
    files => [
               'pmltq_server.conf',
               'pmltq_server.private.conf'
             ],
    force_plugins => [ 'Config::Any::Perl' ]
  });
  $self->plugin('PMLTQ::Server::Mailgun' => $self->config->{mailgun}||{});
  $self->plugin('ParamExpand');
  $self->plugin(ValidateTiny => {explicit => 0});
  $self->plugin(Charset => {charset => 'utf8'});
  $self->plugin(HttpBasicAuth => {
    validate => sub {
      my ($c, $username, $password, $realm) = @_;
      $c->authenticate($username, $password);
      return 1;
    },
    realm => 'PMLTQ'
  });
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

      my $user = $app->mandel->collection('user')->search({
        username => $username,
      })->single;
      my $user_id = $user && check_password($user->password, $password) ? $user->id : undef;
      $self->app->log->debug("Authentication failed for: ${username}") unless $user;
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

  $self->plugin('PMLTQ::Server::Helpers');
  $self->plugin('PMLTQ::Server::FormHelpers');
  $self->add_resource_shortcut();

  # Fake PUT and DELETE methods
  $self->hook(before_dispatch => sub {
    my $c = shift;
    return unless my $method = $c->req->params->param('_method');
    $c->req->method($method);
  });

  # Show log in STDERR
  $self->log->handle(\*STDERR) if $self->mode eq 'development';

  # Setup all helpers
  # $self->setup_helpers(); ###  moved to PMLTQ::Server::Helpers

  # Router
  my $r = $self->routes;

  $r->any('/' => sub {
    my $c = shift;
    unless ($c->is_user_authenticated) {
      $c->redirect_to($c->url_for('admin_login'));
      return;
    }
    $c->redirect_to($c->url_for('admin_welcome'));
  })->name('home');

  # Authetication routes
  my $auth = $r->route('/auth')->to(controller => 'Admin::Auth');
  $auth->any([qw/GET POST/])->to(action => 'index')->name('admin_login');
  $auth->get('/logout')->to(action => 'sign_out')->name('admin_logout');

  my $admin = $r->route('/admin')->over(authenticated => 1, has_priv => 'admin')->to(controller => 'Admin');
  $admin->get->to(action => 'welcome')->name('admin_welcome');
  $admin->resource('user', controller => 'Admin::User', masscreate => 1);
  $admin->resource('treebank', controller => 'Admin::Treebank');
  $admin->resource('sticker', controller => 'Admin::Sticker');

  my $profile = $r->get('/profile')->over(authenticated => 1)->to('Profile#index')->name('user_profile');
  $profile->any([qw/GET POST/] => 'update')->over(has_priv => 'selfupdate')->to('Profile#update');

  # Treebank API version 1
  my $api = $r->under('/v1');

  my $api_auth = $api->route('/auth')->to(controller => 'Auth');
  $api_auth->get->to(action => 'check')->name('auth_check');
  $api_auth->post->to(action => 'sign_in')->name('auth_sign_in');
  $api_auth->delete->to(action => 'sign_out')->name('auth_sign_out');

  $api->get('/treebanks')->to(controller => 'Treebank', action => 'list');
  $api->get('/history')->to(controller => 'History', action => 'list');

  my $treebank = $api->bridge('/treebanks/:treebank')->
    name('treebank')->to(controller => 'Treebank', action => 'initialize');
  $treebank->get ('metadata')->to('#metadata');
  $treebank->post('suggest')->to('#suggest');
  $treebank->get ('data/*file')->to('#data');
  $treebank->get ('node')->to('#node');
  $treebank->get ('type')->to('#type');
  $treebank->get ('node-types')->to('#node_types');
  $treebank->get ('relations')->to('#relations');
  $treebank->get ('relation-target-types')->to('#relation_target_types');
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

      # POST requests - creates  multiple new resources
      $r->route("/$plural/mass")->to(controller => $controller)->post->to(action => 'masscreate')->name("create_$plural") if $params->{masscreate};

      # New form
      $r->get("/$name/new")->to(controller => $controller, action => "new_$name")->name("new_$name");

      # Multiple new form
      $r->get("/$name/mass/new")->to(controller => $controller, action => "new_$plural")->name("new_$plural") if $params->{masscreate};

      # Generate "/$name/:id" route, also handled by controller $name

      # resource routes might be chained, so we need to define an
      # individual id and pass its name to the controller (idname)
      $resource = $r->bridge("/$name/:id", 'id' => qr/[a-z0-9]+/)->
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
