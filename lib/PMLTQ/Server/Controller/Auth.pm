package PMLTQ::Server::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller';

sub index {
  my $c = shift;

  if ($c->req->method eq 'POST') {
    if($c->authenticate($c->param('username'),$c->param('password'))){
      $c->redirect_to($c->url_for('admin_welcome'));
      return;
    } else {
      $c->flash(error => 'Invalid username or password');
      $c->res->code(400); # 400 Invalid parameters
    }
  }

  # Render template "auth/login.html.ep" with a login form
  $c->render(template => 'auth/login');
}

sub sign_out {
  my $c = shift;
  $c->logout();
  $c->redirect_to( '/' );
}

1;
