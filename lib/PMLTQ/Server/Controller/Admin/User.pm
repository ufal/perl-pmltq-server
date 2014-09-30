package PMLTQ::Server::Controller::Admin::User;

# ABSTRACT: Managing users in administration

use Mojo::Base 'Mojolicious::Controller';
use Mango::BSON 'bson_oid';
use List::Util qw(first);
use PMLTQ::Server::Validation;

use PMLTQ::Server::Model::Permission ();
use PMLTQ::Server::Model::Treebank ();

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
  my $c = shift;
  $c->stash(user => undef);
  $c->render(template => 'admin/users/form');
}

sub create {
  my $c = shift;

  if ( my $user_data = $c->_validate_user($c->param('user')) ) {
    my $users = $c->mandel->collection('user');
    my $user = $users->create($user_data);

    $user->save(sub {
      my ($user, $err) = @_;
      if ($err) {
        $c->flash(error => "Database Error: $err");
        $c->stash(user => $user);
        $c->render(template => 'admin/users/form');
      } else {
        $c->redirect_to('show_user', id => $user->id);
      }
    });

    $c->render_later;
  } else {
    $c->flash(error => "Can't save invalid user");
    $c->render(template => 'admin/users/form');
  }
}

sub find_user {
  my $c = shift;
  my $user_id = $c->param('id');

  $c->mandel->collection('user')->search({_id => bson_oid($user_id)})->single(sub {
    my($users, $err, $user) = @_;

    if ($err) {
      $c->flash(error => "$err");
      $c->render_not_found;
      return 0;
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

  if ( my $user_data = $c->_validate_user($c->param('user')) ) {
    $user->patch($user_data, sub {
      my($user, $err) = @_;

      $c->flash(error => "$err") if $err;
      $c->stash(user => $user);
      $c->render(template => 'admin/users/form');
    });

    $c->render_later;
  } else {
    $c->flash(error => "Can't save invalid user");
    $c->render(template => 'admin/users/form', status => 400);
  }
}

sub remove {
  my $c = shift;
  my $user = $c->stash->{user};

  $user->remove(sub {
    my($user, $err) = @_;

    if ($err) {
      $c->flash(error => "$err");
      $c->stash(user => $user);
      $c->render(template => 'admin/users/form');
    } else {
      $c->redirect_to('list_users');
    }
  });

  $c->render_later;
}

sub _validate_user {
  my ($c, $user_data) = @_;

  my $rules = {
    fields => [qw/name username password email is_active available_treebanks permissions/],
    filters => [
      # Remove spaces from all
      [qw/name username password email/] => filter(qw/trim strip/),
      is_active => force_bool(),
      available_treebanks => list_of_dbrefs(PMLTQ::Server::Model::Treebank->model->collection_name),
      permissions => list_of_dbrefs(PMLTQ::Server::Model::Treebank->model->collection_name)
    ],
    checks => [
      [qw/name username password email/] => is_long_at_most(200),
      [qw/username password/] => is_required(),
      email => is_valid_email(),
    ]
  };

  $c->do_validation($rules, $user_data);
}

1;
