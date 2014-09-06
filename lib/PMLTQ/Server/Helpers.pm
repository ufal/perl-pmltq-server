package PMLTQ::Server::Helpers;

use Mojo::Base 'Mojolicious::Plugin';
use Mango::BSON 'bson_oid';

use List::Util qw(min);

###   $self->plugin("PMLTQ::Server::Helpers");



sub register {
  my ($self, $app) = @_;
  $app->helper(mango => sub { shift->app->db });
  $app->helper(mandel => sub { shift->app->mandel });
  $app->app->mandel->initialize;
  
  # COLLECTIONS
  $app->helper(users       => sub { shift->app->mango->db->collection('users') });
  $app->helper(treebanks   => sub { shift->mango->db->collection('treebanks') });
  # ELEMENT IN COLLECTION
  $app->helper(pmltquser        => \&_pmltquser);
  $app->helper(treebank    => \&_treebank);
  # ADD
  $app->helper(adduser     => \&_adduser);
  
  $app->helper(addtreebank => \&_addtreebank);
  # DELETE
  $app->helper(deluser     => \&_deluser);
  $app->helper(deltreebank => \&_deltreebank);
  # UPDATE 
  $app->helper(updateuser     => \&_updateuser);
  #ERROR
  $app->helper(status_error => \&_status_error);
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