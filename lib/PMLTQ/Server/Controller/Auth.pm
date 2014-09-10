package PMLTQ::Server::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller';

sub login {
  my $self = shift;
  # Render template "auth/login.html.ep" with a login form
  $self->render;
}

sub pmltq_logout {
  my $self = shift;
  $self->logout();
  $self->redirect_to( '/' );
}

sub check {
  my $self = shift;
  if($self->authenticate($self->param('username'),$self->param('pass'))){
    $self->redirect_to('/');
  } else {
    $self->flash(err => 'Invalid username or password');
    $self->redirect_to('/');
  }

}

1;
