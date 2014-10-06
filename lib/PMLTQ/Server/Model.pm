package PMLTQ::Server::Model;

# ABSTRACT: Base class for all other models

use Mojo::Base 'Mandel';

use Mango::BSON qw/bson_oid bson_dbref/;

sub initialize {
  my $self = shift;
  my $app = shift;
  $self->SUPER::initialize(@_);

  my $permissions = $self->collection('permission');
  unless ($permissions->count) {
    my @permissions = (
      { name => 'admin', comment => 'Can access everything including administration backend' },
      { name => 'treebanks', comment => 'Can access all treebanks' },
      { name => 'shibboleth', comment => 'User added by Shibboleth and can only login through Shibboleth' },
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
      password => $app->encrypt_password('admin'),
      permissions => [bson_dbref($permissions->model->collection_name, shift @{$permissions->search({name => 'admin'})->distinct('_id')})]
    });
    $admin->save;
  }
}

1;
