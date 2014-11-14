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
    $c->render(template => 'admin/users/form', status => 400);
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

  if ( my $user_data = $c->_validate_user($c->param('user'), $user) ) {
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
  my ($c, $user_data, $user) = @_;

  $user_data ||= {};

  $user_data = {
    available_treebanks => [],
    permissions => [],
    stickers => "",
    %$user_data
  };
  my $rules = {
    fields => [qw/name username password password_confirm email is_active available_treebanks permissions/],
    filters => [
      # Remove spaces from all
      [qw/name username email/] => filter(qw/trim strip/),
      ($user_data->{password} ? (password => encrypt_password()) : ()),
      is_active => force_bool(),
      available_treebanks => list_of_dbrefs(PMLTQ::Server::Model::Treebank->model->collection_name),
      permissions => list_of_dbrefs(PMLTQ::Server::Model::Permission->model->collection_name),
      stickers => [sub {return [split(',',shift)]},list_of_dbrefs(PMLTQ::Server::Model::Sticker->model->collection_name)]
    ],
    checks => [
      [qw/name username password password_confirm email/] => is_long_at_most(200),
      username => [is_required(), sub {
        my $username = shift;
        my $count = $c->mandel->collection('user')->search({
          username => $username, 
          ($user ? (_id => { '$ne' => $user->id }) : ())
        })->count;
        return $count > 0 ? "Username '$username' already exists" : undef;  
      }],
      [qw/password password_confirm/] => is_required_if(!$user),
      password => is_password_equal(password_confirm => "Passwords don't match"),
      email => is_valid_email(),
    ]
  };

  $user_data = $c->do_validation($rules, $user_data);

  return $user_data unless $user_data; # Fail if not valid

  # Replace empty password if possible
  unless ($user_data->{password}) {
    $user_data->{password} = $user->password if $user;
  }

  return $user_data;
}

1;
