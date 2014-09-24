package PMLTQ::Server::Helpers;

use Mojo::Base 'Mojolicious::Plugin';
use Mango::BSON 'bson_oid';
use Digest::SHA qw(sha1_hex);

use List::Util qw(min any);

###   $self->plugin("PMLTQ::Server::Helpers");



sub register {
  my ($self, $app, $conf) = @_;
  $app->helper(mango => sub { shift->app->db });
  $app->helper(mandel => sub { shift->app->mandel });
  $app->mandel->initialize;

  # History
  $app->helper(history_key => \&_history_key);

  # Add admin user if not present
  $app->mandel->collection('user')->count(sub {
    my ($users, $err, $int) = @_;

    return unless ($int == 0 && !$err);
    $app->mandel->collection('permission')->search({name => 'admin'})->single(sub {
      my($permissions, $err, $admin_permission) = @_;
      unless ($admin_permission) {
        $admin_permission = $permissions->create({
          name => 'admin',
          comment => 'All powerfull admin'
        });
        $admin_permission->save();
      }

      my $admin = $users->create({
        name => 'Super Admin',
        username => 'admin',
        password => 'admin',
      });

      $admin->save(sub {
        my ($admin, $err) = @_;

        $app->log->error("Creating admin user failed: $err") if $err;
        $admin->push_permissions($admin_permission) if ($admin);
      });
    });
  });

  # Common access helpers
  $app->helper(users => sub { shift->mandel->collection('user') });
  $app->helper(user => sub {
    my $self = shift;
    my $user = $self->stash('user');
    unless ($user) {
      $user = $self->users->create();
      $self->stash(user => $user);
    }
    return $user;
  });

  $app->helper(permission_options => sub {
    my ($self, $selected) = @_;
    map {
      my $p = $_;
      {
        value => $p->id,
        label => $p->name,
        selected => any {$p->id eq $_->id } @$selected
      }
    } @{$self->permissions->all}
  });

  $app->helper(treebank_options => sub {
    my ($self, $selected) = @_;
    map {
      my $p = $_;
      {
        value => $p->id,
        label => $p->name,
        selected => any {$p->id eq $_->id } @$selected
      }
    } @{$self->treebanks->all}
  });

  $app->helper(treebanks     => sub { shift->mandel->collection('treebank') });
  $app->helper(treebank => sub {
    my $self = shift;
    my $treebank = $self->stash('treebank');
    unless ($treebank) {
      $treebank = $self->treebanks->create();
      $self->stash(treebank => $treebank);
    }
    return $treebank;
  });
  $app->helper(permissions   => sub { shift->mandel->collection('permission') });
  $app->helper(history       => sub { shift->mandel->collection('history') });
  $app->helper(drivers       => sub { [{id=>'pg',name=>"PostgreSQL"}] });

  # # COLLECTIONS
  # $self->helper(users       => sub { shift->mango->collection('users') });
  # $self->helper(treebanks   => sub { shift->mango->collection('treebanks') });
  # # ELEMENT IN COLLECTION
  # $self->helper(pmltquser        => \&_pmltquser);
  # $self->helper(treebank    => \&_treebank);
  # # ADD
  # $self->helper(adduser     => \&_adduser);

  # $self->helper(addtreebank => \&_addtreebank);
  # # DELETE
  # $self->helper(deluser     => \&_deluser);
  # $self->helper(deltreebank => \&_deltreebank);
  # # UPDATE
  # $self->helper(updateuser     => \&_updateuser);

  #ERROR
  $app->helper(status_error => \&_status_error);
}


sub _history_key {
  my $self = shift;

  my $current_user = $self->current_user;
  return $current_user->id if $current_user;

  my $key = $self->session->{history_key};
  unless ($key) {
    $key = sha1_hex(time() . rand() . (2 * rand()));
    $self->session(history_key => $key);
  }
  return $key;
}

sub _pmltquser {
  my ($self,$username) = @_;
  return $self->users->find_one({'username' => $username})
}


sub _treebank{ my ($self,$tbname) = @_;
  return $self->treebanks->find_one({'name' => $tbname})
}


sub _adduser{
  #my ($self,$username,$password,$email,@treebanks) = @_;
  #return 0 if $self->user($username);
  my ($self,$user) = @_;
  return 0 if $self->pmltquser($user->{'username'});
  $user->{'privs'}->{'selfupdate'} = 1 if $user->{'privs'}->{'admin'};
  $self->users->insert($user);
  return 1;
}


sub _addtreebank {  my ($self,$treebank) = @_;
  return 0 if $self->treebank($treebank->{'name'});
  $self->treebanks->insert($treebank);
  return 1;
}


sub _deluser{
  my ($self,$username) = @_;
  return 0 unless $self->pmltquser($username);
  $self->users->remove({'username'=>$username});
  return 1;
}


sub _deltreebank{
  my ($self,$tbname) = @_;
  return 0 unless $self->treebank($tbname);
  $self->treebanks->remove({'name'=>$tbname});
  return 1;
}


sub _updateuser {
  my($self,$username,$user) = @_;

  #my $username = $d->{'username'};
  #my $data =  $d->{'data'};

  # probíhá update všeho !!! nelze projet cyklem, musíme si předem uložit ostatní údaje - nejlépe vytágnout usera z databáze, aktualizovat ho a pak ho nahrát do databáze
  print STDERR "UPDATE: $user\n";
  print STDERR  "\tname=$username\n";
  return 0 unless $user;
  $user->{'privs'}->{'selfupdate'} = 1 if $user->{'privs'}->{'admin'};
  $self->users->update({username=>$username},$user);
  return 1;
}


sub _status_error {
  my ($self, @errors) = @_;

  die __PACKAGE__, 'No errors to render' unless @errors;

  if (@errors == 1) {
    my $error = shift @errors;
    $self->res->code($error->{code});
    $self->render(json => { error => $error->{message} });
  } else {
    # find lowest code and display only those errors
    my $code = min map { $_->{code} } @errors;

    @errors = grep { $_->{code} == $code } @errors;
    return $self->status_error(@errors) if @errors == 1;

    $self->res->code($code);
    $self->render(json => {
      message => 'The request cannot be fulfilled because of multiple errors',
      errors => [ map { $_->{message} } @errors ]
    });
  }
}


1;
