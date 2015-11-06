package PMLTQ::Server::Controller::User;

# ABSTRACT: Managing query files

use Mojo::Base 'Mojolicious::Controller';

sub is_authenticated {
  my $c = shift;

  unless ($c->is_user_authenticated) {
    $c->status_error({
      code => 401,
      message => 'Authentication required'
    });

    return;
  }

  return 1;
}

1;