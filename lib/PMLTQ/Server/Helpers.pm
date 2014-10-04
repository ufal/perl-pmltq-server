package PMLTQ::Server::Helpers;

use Mojo::Base 'Mojolicious::Plugin';
use Mango::BSON 'bson_oid';
use Digest::SHA qw(sha1_hex);

use List::Util qw(min any);
use Scalar::Util ();

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

  $app->helper(field_options => sub {
    my ($self, $name, $id_accessor, $label_accessor) = @_;
    $id_accessor //= 'id';
    $label_accessor //= 'label';

    return {
      map {
        ($_->$id_accessor => $_->$label_accessor)
      } @{$self->mandel->collection($name)->all}
    }
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
  $app->helper(drivers       => sub { state $drivers = [ [Pg => 'PostgreSQL'] ] });

  # HTML
  $app->helper(form_field => sub {
    my ($c, $type, $name) = (shift, shift, shift);
    my @args = @_;

    my $id = _dom_id($name);
    my @path = split /\Q./, $name;
    my $value = _lookup_stash_value($c, @path);
    shift @path if @path > 1;
    my $field_name = join '.', @path;
    my $label = join ' ', map { ucfirst } @path;
    my $error = $c->validator_error($field_name);
    $c->tag('div', class => ('form-group' . ($error ? ' has-error' : '')), sub {
      my $content = $c->tag('label', for => $id, $label . ':');
      $content .= $c->$type($name => $value, class => 'form-control', placeholder => $label, @args);
      $content .= $c->tag('p', class => 'text-danger', $error) if $error;
      return $content;
    });  
  });

  $app->helper(password_field_with_value => sub {
    my ($c, $name, $value) = (shift, shift, shift);
    $c->tag('input', type => 'password', name => $name, value => $value, @_); 
  });

  # ERROR
  $app->helper(status_error => \&_status_error);
}

sub _lookup_stash_value {
  my ($c, @path) = @_;

  my $object = $c->stash;

  while(defined(my $accessor = shift @path) && $object) {
    my $isa = ref($object);

    # We don't handle the case where one of these return an array
    if(Scalar::Util::blessed($object) && $object->can($accessor)) {
      $object = $object->$accessor;
    } elsif($isa eq 'HASH') {
      # If blessed and !can() do we _really_ want to look inside?
      $object = $object->{$accessor};
    } elsif($isa eq 'ARRAY') {
      die "non-numeric index '$accessor' used to access an ARRAY"
          unless $accessor =~ /^\d+$/;

      $object = $object->[$accessor];
    } else {
      my $type = $isa || 'type that is not a reference';
      die "cannot use '$accessor' on a $type";
    }
  }

  return $object;
}

sub _dom_id
{
  my @name = @_;
  s/[^\w]+/-/g for @name;
  join '-', @name;
}
 
sub _default_label
{
  my $label = (split /\Q./, shift)[-1];
  $label =~ s/[^-a-z0-9]+/ /ig;
  ucfirst $label;
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
