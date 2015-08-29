package PMLTQ::Server::Authentication;

use Mojo::Base 'Mojolicious::Plugin';
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
  my $user = $c->db->resultset('User')->find($user_id);
  $c->app->log->debug('Failed to load user.') unless $user;
  return $user;
}

sub validate_user {
  my ($self, $c, $username, $password, $user_data) = @_;

  if ($user_data && $user_data->{persistent_token}) {
    return $self->register_or_load($c, { map { ($_ => $user_data->{$_}) } qw/persistent_token organization provider/ }, $user_data);
  }
  my $user = $c->db->resultset('User')->single({ username => $username });
  my $user_id = $user && $user->check_password($password) ? $user->id : undef;
  $c->app->log->debug("Authentication failed for: ${username}") unless $user;
  return defined $user_id ? "$user_id" : undef;
}

sub register_or_load {
  my ($self, $c, $search, $data) = @_;

  my $users_rs = $c->db->resultset('User');
  my $user = $users_rs->single($search);

  unless ($user) {
    $user = $users_rs->new_result({
      is_active => 1,
      %$data,
      is_admin => 0
    });
    $user->insert();
  }

  return $user->id;
}

1;
