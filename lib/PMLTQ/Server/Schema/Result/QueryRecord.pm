package PMLTQ::Server::Schema::Result::QueryRecord;

use Mojo::Base qw/PMLTQ::Server::Schema::Result/;

__PACKAGE__->table('query_records');

__PACKAGE__->load_components('InflateColumn::DateTime', 'TimeStamp');

__PACKAGE__->add_columns(
  id            => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
  name          => { data_type => 'varchar', is_nullable => 1, size => 120 },
  query         => { data_type => 'text', is_nullable => 1, is_serializable => 1 },
  user_id       => { data_type => 'integer', is_foreign_key => 1, is_nullable => 0 },
  query_file_id => { data_type => 'integer', is_foreign_key => 1, is_nullable => 1 },
  created_at    => { data_type => 'datetime', is_nullable => 0, set_on_create => 1, set_on_update => 0 },
  last_use      => { data_type => 'datetime', is_nullable => 0, set_on_create => 1, set_on_update => 1 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
  query_file => 'PMLTQ::Server::Schema::Result::QueryFile', 'query_file_id'
);

__PACKAGE__->belongs_to(
  user => 'PMLTQ::Server::Schema::Result::User', 'user_id'
);

1;
