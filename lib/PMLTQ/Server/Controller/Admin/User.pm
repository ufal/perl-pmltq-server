package PMLTQ::Server::Controller::Admin::User;

# ABSTRACT: Managing users in administration

use Mojo::Base 'Mojolicious::Controller';
use Mango::BSON 'bson_oid';
use List::Util qw(first);

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
  #pozor !!! může být buď reference na pole nebo řetězec, závisí na počtu prvků !!! $c->param('user')->{'permissions'};
  for (qw/available_treebanks permissions/){$c->param('user')->{$_} = [$c->param('user')->{$_}] unless ref($c->param('user')->{$_}) eq 'ARRAY' or not($c->param('user')->{$_});}
  my @avtree = map {my $id = $_;first {$id eq $_->id} @{$c->treebanks->all}} @{$c->param('user')->{'available_treebanks'}};
  $c->param('user')->{'available_treebanks'} = [];
  my @perms = map {
                    my $id = $_;
                    print STDERR "ID=$id\n";
                    first {$id eq $_->id} @{$c->permissions->all}
                  } 
                  @{$c->param('user')->{'permissions'}};
  $c->param('user')->{'permissions'} = [];
  
  # TODO: validate input
  my $users = $c->mandel->collection('user');
  my $user = $users->create($c->param('user'));

  $user->save(sub {
    my ($user, $err) = @_;
    if ($err) {
      $c->flash(error => "$err");
      $c->stash(user => $user);
      $c->render(template => 'admin/users/form');
    } else {
      $user->push_available_treebanks($_) for (@avtree);
      $user->push_permissions($_) for (@perms);
      $c->redirect_to('show_user', id => $user->id);
    }
  });

  $c->render_later;
}

sub find_user {
  my $c = shift;
  my $user_id = $c->param('id');

  $c->mandel->collection('user')->search({_id => bson_oid($user_id)})->single(sub {
    my($users, $err, $user) = @_;

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
  for (qw/available_treebanks permissions/){$c->param('user')->{$_} = [$c->param('user')->{$_}] unless ref($c->param('user')->{$_}) eq 'ARRAY' or not($c->param('user')->{$_});}
  my @avtree = map {my $id = $_;first {$id eq $_->id} @{$c->treebanks->all}} @{$c->param('user')->{'available_treebanks'}};
  $c->param('user')->{'available_treebanks'} = [];
  
  my @perms = map {my $id = $_;first {$id eq $_->id} @{$c->permissions->all}} @{$c->param('user')->{'permissions'}};
  $c->param('user')->{'permissions'} = [];
  
  # TODO: validate input
  $user->patch($c->param('user'), sub {
    my($user, $err) = @_;

    $c->flash(error => "$err") if $err;
    $user->push_available_treebanks($_) for (@avtree);
    $user->push_permissions($_) for (@perms);
    $c->stash(user => $user);
    $c->render(template => 'admin/users/form');
  });

  $c->render_later;
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

1;
