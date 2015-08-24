package PMLTQ::Server::Authentication;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::JSON;
use Mango::BSON qw/bson_oid bson_dbref/;
use PMLTQ::Server::Model::Permission ':constants';
use PMLTQ::Server::Validation 'check_password';

sub register {
  my ($self, $app) = @_;

  $app->plugin(Authentication => {
    autoload_user => 0,
    session_key   => 'auth_data',
    our_stash_key => 'auth',
    load_user     => sub { $self->load_user(@_) },
    validate_user => sub { $self->validate_user(@_) }
  });
}

sub load_user {
  my ($self, $c, $user_id) = @_;
  my $user = $c->mandel->collection('user')->search({_id => bson_oid($user_id)})->single;
  $c->app->log->debug('Failed to load user.') unless $user;
  return $user;
}

sub validate_user {
  my ($self, $c, $username, $password, $user_data) = @_;

  if ($user_data && $user_data->{persistent_token}) {
    return $self->register_or_load($c, $user_data->{persistent_token}, $user_data->{organization}, $user_data);
  }
  my $user = $c->mandel->collection('user')->search({
    username => $username,
  })->single;
  my $user_id = $user && check_password($user->password, $password) ? $user->id : undef;
  $c->app->log->debug("Authentication failed for: ${username}") unless $user;
  return defined $user_id ? "$user_id" : undef;
}

sub register_or_load {
  my ($self, $c, $persistent_token, $organization, $data) = @_;

  my $users = $c->mandel->collection('user');
  my $user = $users->search({
    persistent_token => $persistent_token,
    organization => $organization
  })->single;

  unless ($user) {
    my $permissions = $c->mandel->collection('permission');
    # Create new record
    # This is a copy from Controller::Admin::User
    # TODO: refactor user creation
    my $user_data = {
      available_treebanks => [],
      permissions => [bson_dbref($permissions->model->collection_name, shift @{$permissions->search({name => ALL_TREEBANKS})->distinct('_id')})],
      stickers => '',
      is_active => Mojo::JSON->true,
      provider => '',
      %$data
    };

    $user = $users->create($user_data)->save();
  }

  my $user_id = $user->id;
  return "$user_id";
}

1;
