package PMLTQ::Server::Controller::Admin::User;

# ABSTRACT: Managing users in administration

use Mojo::Base 'Mojolicious::Controller';

=head1 METHODS

=head2 list

List all users in the database

=cut

sub list {
  my $c = shift;

  $c->mandel->collection('user')->all(sub {
    my($collection, $err, $users) = @_;

    $c->flash(error => "Database Error: $err") if $err;

    $c->stash(users => $users);
    $c->render(template => 'admin/users/list');
  });

  $c->render_later;
}

sub new_user {
  shift->render(template => 'admin/users/form');
}

sub create {
  my $c = shift;

  # TODO: validate input

  $c->mandel->collection('user')->create($c->param('user'), sub {
    my($user, $err) = @_;
    if ($err) {
      $c->flash(error => "$err");
      $c->new_user;
    } else {
      my $redirect_url = $c->url_for('show_user', user_id => $user->id);
      $c->redirect_to($redirect_url);
    }
  });

  $c->render_later;
}

sub find_user {
  my $c = shift;
  my $user_id = $c->param('user_id');

  $c->mandel->collection('user')->search({_id => $user_id})->single(sub {
    my($collection, $err, $user) = @_;

    if ($err) {
      $c->flash(error => "$err");
      $c->render_not_found;
      return;
    }

    $c->stash(user => $user);
    $c->continue;
  });

  return undef;
}

sub show {
  my $c = shift;
  $c->render(template => 'admin/users/form');
}

sub update {
  my $c = shift;
  my $user = $c->stash->{user};

  # TODO: validate input
  $user->patch($c->param('user'), sub {
    my($user, $err) = @_;

    $c->flash(error => "$err") if $err;
    $c->stash(user => $user);
    $c->render(template => 'admin/users/form');
  });

  $c->render_later;
}

sub delete {
  my $c = shift;
  my $user = $c->stash->{user};

  # TODO: validate input
  $user->patch($c->remove('user'), sub {
    my($user, $err) = @_;

    if ($err) {
      $c->flash(error => "$err") ;
      $c->stash(user => $user);
      $c->render(template => 'admin/users/form');
    } else {
      my $redirect_url = $c->url_for('list_users');
      $c->redirect_to($redirect_url);
    }
  });

  $c->render_later;
}

1;
