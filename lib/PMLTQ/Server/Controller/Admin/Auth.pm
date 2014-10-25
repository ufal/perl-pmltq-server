package PMLTQ::Server::Controller::Admin::Auth;
use Mojo::Base 'PMLTQ::Server::Controller::Auth';

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
      $c->app->log->debug('Invalid credentials');
      $c->flash(error => 'Invalid username or password');
      $c->res->code(400); # 400 Invalid parameters
    }
  }

  $c->render(template => 'auth/login');
}

sub sign_out {
  my $c = shift;
  $c->logout();
  $c->flash(success => 'Successfully logged out');
  $c->redirect_to('/');
}

1;
