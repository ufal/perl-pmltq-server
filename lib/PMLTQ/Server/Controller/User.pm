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

sub history {
  my $c = shift;
  return unless $c->user_authenticated;
  return $c->stash('history') // PMLTQ::Server::Controller::History->initialize();
}

sub is_query_file_allowed {
  my $c = shift;
  unless ($c->current_user && $c->current_user->allow_query_lists) {
    $c->status_error({
      code => 401,
      message => 'Unauthorized'
    });

    return;
  }

  return 1;
}

sub is_history_allowed {
  my $c = shift;
  unless ($c->current_user && $c->current_user->allow_history) {
    $c->status_error({
      code => 401,
      message => 'Unauthorized'
    });

    return;
  }

  return 1;
}

1;