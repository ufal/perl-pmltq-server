package PMLTQ::Server::Schema::Result::QueryFile;

use Mojo::Base qw/PMLTQ::Server::Schema::Result/;

__PACKAGE__->table('query_files');

__PACKAGE__->load_components('InflateColumn::DateTime', 'TimeStamp');

__PACKAGE__->add_columns(
  id          => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
  name        => { data_type => 'varchar', is_nullable => 0, size => 120 },
  user_id     => { data_type => 'integer', is_foreign_key => 1, is_nullable => 1 },
  created_at  => { data_type => 'datetime', is_nullable => 0, set_on_create => 1, set_on_update => 0 },
  last_use    => { data_type => 'datetime', is_nullable => 0, set_on_create => 1, set_on_update => 1 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint('name_unique', ['name', 'user_id']);

__PACKAGE__->belongs_to(
  user => 'PMLTQ::Server::Schema::Result::User', 'user_id'
);

__PACKAGE__->has_many(
  queries => 'PMLTQ::Server::Schema::Result::Query',
  { 'foreign.query_file_id' => 'self.id' },
  { cascade_copy => 0, cascade_delete => 1 },
);

1;
