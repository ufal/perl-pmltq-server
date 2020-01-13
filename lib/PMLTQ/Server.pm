package PMLTQ::Server;
use Mojo::Base 'Mojolicious';

use File::Spec;
use PMLTQ::Server::Schema;
use Lingua::EN::Inflect 1.895 qw/PL/;
use PMLTQ::Server::Validation 'check_password';
use PMLTQ;
use Treex::PML;

has database_connect_info => sub { $_[0]->config->{database} };

has db => sub { state $schema = PMLTQ::Server::Schema->connect(shift->database_connect_info) };

# This method will run once at server start
sub startup {
  my $self = shift;

  # Show log in STDERR
  $self->log->handle(\*STDERR) if ($self->mode eq 'development' or $self->mode eq 'test');

  $self->log->debug('Running in ' . $self->mode . ' mode');

  # Get configuration first
  $self->plugin('PMLTQ::Server::Config');

  # Setup resources directory
  Treex::PML::AddResourcePathAsFirst(PMLTQ->resources_dir);

  $self->plugin('PMLTQ::Server::Mailgun' => $self->config->{mailgun}||{});
  $self->plugin('PMLTQ::Server::ValidateTiny' => {explicit => 0});
  # $self->plugin(Charset => {charset => 'utf8'}); not in Mojolicious v7+
  $self->plugin(HttpBasicAuth => {
    validate => sub {
      my ($c, $username, $password, $realm) = @_;
      $c->authenticate($username, $password);
      return 1;
    },
    realm => 'PMLTQ'
  });
  $self->plugin('PMLTQ::Server::Authentication');
  $self->plugin('PMLTQ::Server::Helpers');
  $self->add_resource_shortcut();

  # Router
  my $r = $self->routes;

  # Treebank API version 1
  my $api = $r->under('/v1');

  my $admin = $api->under('/admin')->to(controller => 'Auth', action => 'is_admin');
  $admin->resource('user', controller => 'Admin::User');
  $admin->resource('treebank', controller => 'Admin::Treebank');
  $admin->resource('tag', controller => 'Admin::Tag');
  $admin->resource('server', controller => 'Admin::Server');
  $admin->resource('language', controller => 'Admin::Language');
  $admin->resource('language-group', controller => 'Admin::LanguageGroup');

  # my $profile = $r->get('/profile')->over(authenticated => 1)->to('Profile#index')->name('user_profile');
  # $profile->any([qw/GET POST/] => 'update')->over(has_priv => 'selfupdate')->to('Profile#update');

  my $api_auth = $api->route('/auth')->to(controller => 'Auth');
  $api_auth->get->to(action => 'check')->name('auth_check');
  $api_auth->post->to(action => 'sign_in')->name('auth_sign_in');
  $api_auth->delete->to(action => 'sign_out')->name('auth_sign_out');
  $api_auth->get('shibboleth')->to(action => 'sign_in_shibboleth')->name('auth_shibboleth');
  $api_auth->get('ldc')->to(action => 'sign_in_ldc')->name('auth_ldc');

  $api->get('/treebanks')->to(controller => 'Treebank', action => 'list')->name('treebanks');

  my $user = $api->under('/user')->to(controller => 'User', action => 'is_authenticated');
  my $query_file = $user->resource('query-file', controller => 'User::QueryFile', permission => 'is_owner');
  $query_file->resource('query', controller => 'User::QueryFile::QueryRecord', permission => 'is_owner');

  $user->get('history')->to(controller => 'History', action => 'list')->name('history');

  $api->get('public-query')->to(controller => 'PublicQuery', action => 'list')->name('public_query_tree');

  my $public_file = $api->under('/public-query-list/:user_id', ['user_id' => qr/[a-z0-9_-]+/])->
    name('public_query_file')->to(controller => 'PublicQuery', action => 'initialize_single');
  $public_file->get->to('#get');



  my $treebank = $api->under('/treebanks/:treebank_id', ['treebank_id' => qr/[a-z0-9_-]+/])->
    name('treebank')->to(controller => 'Treebank', action => 'initialize_single');
  $treebank->get->to('#metadata');
  $treebank->get ('metadata')->to('#metadata');
  $treebank->post('suggest')->to('#suggest');
  $treebank->get ('data/*file')->to('#data');
  $treebank->get ('node')->to('#node');
  $treebank->get ('type')->to('#type');
  $treebank->get ('schema')->to('#schema');
  $treebank->get ('node-types')->name('node_types')->to('#node_types');
  $treebank->get ('relations')->to('#relations');
  $treebank->get ('relation-target-types')->name('relation_target_types')->to('#relation_target_types');
  $treebank->get ('documentation')->to('#documentation');
  $treebank->post('query')->to(controller => 'Query', action => 'query');
  $treebank->post('query/svg')->to(controller => 'Svg', action => 'query_svg')->name('query_svg');
  # $treebank->post('svg')->to(controller => 'Svg', action => 'result_svg')->name('result_svg');
  $treebank->get('svg')->to(controller => 'Svg', action => 'result_svg')->name('result_svg');
}

sub add_resource_shortcut {
  shift->routes->add_shortcut(
    resource => sub {
      my $r = shift;
      my $name = shift;
      my $params = { @_ ? (ref $_[0] ? %{ $_[0] } : @_) : () };

      my $url = PL($name, 10);
      my $controller = $params->{controller} || "$name#";
      my $permission = $params->{permission} || 'true';
      my $plural_name = $url;

      $name =~ s/-/_/;
      $plural_name =~ s/-/_/;
      my $entity_id = "${name}_id";

      my $parent = undef;
      if ($r->name =~ m/(.*)_resource$/) {
        $parent = $1;
        $plural_name = "${parent}_${plural_name}";
        $name = "${parent}_${name}";
      }

      # Generate "/$url" route, handled by controller $name
      my $resource = $r->route("/$url")->to(controller => $controller, parent_entity => $parent);

      # GET requests - lists the collection of this resource
      $resource->get->to(action => 'list')->name("list_$plural_name");

      $resource->put->to(action => 'update_list')->name("update_list_$plural_name");

      # POST requests - creates a new resource
      $resource->post->to(action => 'create')->name("create_$name");

      # Generate "/$url/:$entity_id" route, also handled by controller $name

      # resource routes might be chained, so we need to define an
      # individual id and pass its name to the controller (idname)
      $resource = $r->under("/$url/:${entity_id}" => ["${entity_id}" => qr/[0-9]+/])
        ->to(controller => $controller, action => 'find', entity_name => $name, entity_id_name => $entity_id, parent_entity => $parent)
        ->under("/")
        ->to(controller => $controller, action => $permission)
        ->name("${name}_resource");

      # GET requests - lists a single resource
      $resource->get->to(controller => $controller, action => 'get')->name("get_$name");

      # DELETE requests - deletes a resource
      $resource->delete->to(controller => $controller, action => 'remove')->name("delete_$name");

      # PUT requests - updates a resource
      $resource->put->to(controller => $controller, action => 'update')->name("update_$name");

      # return "/$url/:$entity_id" route so that potential child routes make sense
      return $resource;
    }
  );
}
1;
