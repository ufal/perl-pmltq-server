package PMLTQ::Server::Model::User;

# ABSTRACT: Model representing an user

use Mandel::Document (
  name => 'PMLTQ::Server::Document',
  collection_name => 'users'
);

use Types::Standard qw(Str ArrayRef Bool HashRef Ref);
use PMLTQ::Server::Model::Permission 'ALL_TREEBANKS';
use List::Util qw(any);
use DateTime;
use DateTime::Format::Strptime;

has_many histories => 'PMLTQ::Server::Model::History';

field [qw/name username password email/] => (isa => Str);

field [qw/is_active/] => (isa => Bool, builder => sub {  return 1; });

field [qw/last_login/] => (isa => Ref['DateTime'], builder => sub { DateTime->now });

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


sub mail {
  my $self = shift;
  my $template = shift;
  my $subject = $template->{subject};
  my $text = $template-> {text};
  my %args = (@_, 'NAME' => $self->name, 'USERNAME' => $self->username, 'EMAIL' => $self->email, 'PASSWORD' => $self->password) ;
  $text =~ s/%%(.*?)%%/$args{"$1"}||"%%$1%%"/ge;  ## if $1 is not in %args %%$1%% is not substituted
  return  {
      to => $self->email,
      subject => $subject,
      text => $text
    }
}

sub get_last_login {
  my $self = shift;
  my $pattern = shift//'%Y-%m-%d %R';

  my $last_login = $self->last_login;

  $last_login = DateTime::Format::Strptime->new(
    pattern => '%Y-%m-%dT%H:%M:%S',
    time_zone => 'local'
  )->parse_datetime($last_login) unless ref $last_login && $last_login->isa('DateTime');

  return 'never' unless $last_login;

  return $last_login->strftime($pattern);
}

sub logged {
  my $self = shift;
  $self->patch({last_login => DateTime->now()}, sub {my($user, $err) = @_;});
}


1;
