package PMLTQ::Server::Model::User;

# ABSTRACT: Model representing an user

use PMLTQ::Server::Document 'users';

use Types::Standard qw(Str ArrayRef Bool HashRef);
use PMLTQ::Server::Model::Permission 'ALL_TREEBANKS';
use List::Util qw(any);

has_many histories => 'PMLTQ::Server::Model::History';

field [qw/name username password email/] => (isa => Str);

field [qw/is_active/] => (isa => Bool);

list_of available_treebanks => 'PMLTQ::Server::Model::Treebank';

list_of permissions => 'PMLTQ::Server::Model::Permission';

list_of stickers => 'PMLTQ::Server::Model::Sticker';

sub has_permission {
  my ($self, $permission) = @_;

  my $permissions = $self->permissions;
  return 0 unless @{$permissions};
  any { $_->name||'' eq $permission } @{$permissions};
}

sub can_access_treebank {
  my ($self, $treebank_name) = @_;

  return 1 if $self->has_permission(ALL_TREEBANKS);

  my $treebanks = $self->available_treebanks;
  any { $_->name||'' eq $treebank_name } @{$treebanks};
}

sub TO_JSON {
  my $self = shift;

  my $data = { %{$self->data} }; # shallow clone of the hash
  delete $data->{password};
  $data->{permissions} = $self->permissions;
  $data->{available_treebanks} = $self->available_treebanks;
  # TODO add stickers
  return $data;
}


sub registration {
  my $self = shift;
  my $home = shift;
  my $password = shift;
  return {
      to => $self->email,
      subject => 'registration',
      data => 'Dear '.$self->name.',

your account has been created. Please remember the following login data:
      username: "'.$self->username.'"
      password: "'.$password.'"
You can follow '.$home.' to login.

Sincerely,
PMLTQ Team
'
    };
}



1;
