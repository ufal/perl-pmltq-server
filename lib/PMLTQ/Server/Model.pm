package PMLTQ::Server::Model;

# ABSTRACT: Base class for all other models

use Mojo::Base 'Mandel';

use Mango::BSON qw/bson_oid bson_dbref/;
use PMLTQ::Server::Validation 'encrypt_password';
use PMLTQ::Server::Model::Permission ':constants';
use DateTime;

sub initialize {
  my $self = shift;
  my $app = shift;
  $self->SUPER::initialize(@_);

  my $permissions = $self->collection('permission');
  unless ($permissions->count) {
    my @permissions = (
      { name => ADMIN, comment => 'Can access everything including administration backend' },
      { name => ALL_TREEBANKS, comment => 'Can access all treebanks' },
    );

    for (@permissions) {
      next if $permissions->search({name => $_->{name}})->count;
      $permissions->create($_)->save;
    }
  }

  my $users = $self->collection('user');
  unless ($users->count) {
    my $admin = $users->create({
      name => 'Super Admin',
      username => 'admin',
      password => encrypt_password()->('admin'),
      permissions => [bson_dbref($permissions->model->collection_name, shift @{$permissions->search({name => 'admin'})->distinct('_id')})],
    });
    $admin->save;
  }
}

1;
