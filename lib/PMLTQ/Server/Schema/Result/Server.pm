package PMLTQ::Server::Schema::Result::Server;

use Mojo::Base qw/PMLTQ::Server::Schema::Result/;

__PACKAGE__->table('servers');

__PACKAGE__->add_columns(
  id       => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
  name     => { data_type => 'varchar', is_nullable => 0, size => 120 },
  host     => { data_type => 'varchar', is_nullable => 0, size => 120 },
  port     => { data_type => 'integer', is_nullable => 0 },
  username => { data_type => 'varchar', is_nullable => 1, size => 120 },
  password => { data_type => 'varchar', is_nullable => 1, size => 120 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint('name_unique', ['name']);

__PACKAGE__->has_many(
  treebanks => 'PMLTQ::Server::Schema::Result::Treebank',
  { 'foreign.server_id' => 'self.id' },
  { cascade_copy => 0, cascade_delete => 1 },
);

1;
