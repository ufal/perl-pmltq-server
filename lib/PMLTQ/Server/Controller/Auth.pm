package PMLTQ::Server::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller';

sub login {
  my $self = shift;

  # Render template "auth/login.html.ep" with a login form
  $self->render;
}

1;
