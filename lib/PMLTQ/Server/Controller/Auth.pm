package PMLTQ::Server::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller';

use PMLTQ::Server::Validation;

sub index {
  my $c = shift;

  if ($c->req->method eq 'POST') {
    my $auth_data = $c->param('auth');
    if(($auth_data = $c->_validate_auth($auth_data))
      && $c->authenticate($auth_data->{username}, $auth_data->{password})) {
      $c->flash(success => 'Successfully logged in');
      $c->redirect_to($c->url_for('admin_welcome'));
      return;
    } else {
      $c->flash(error => 'Invalid username or password');
      $c->app->log->debug('Invalid credentials');
      $c->res->code(400); # 400 Invalid parameters
    }
  }

  # Render template "auth/login.html.ep" with a login form
  $c->render(template => 'auth/login');
}

sub sign_out {
  my $c = shift;
  $c->logout();
  $c->flash(success => 'Successfully logged out');
  $c->redirect_to('/');
}

sub _validate_auth {
  my ($c, $auth_data) = @_;

  my $rules = {
    fields => [qw/username password/],
    filters => [
      username => filter(qw/trim strip/),
      password => sub { $c->encrypt_password(@_) }
    ],
    checks => [
      [qw/username password/] => is_required()
    ]
  };

  $c->do_validation($rules, $auth_data);
}

1;
