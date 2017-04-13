package PMLTQ::Server::Schema::Result::QueryRecord;

use Mojo::Base qw/PMLTQ::Server::Schema::Result/;

__PACKAGE__->table('query_records');

__PACKAGE__->load_components('EncodedColumn', 'InflateColumn::DateTime', 'TimeStamp');

__PACKAGE__->add_columns(
  id                  => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
  name                => { data_type => 'varchar', is_nullable => 1, size => 120 },
  query               => { data_type => 'text', is_nullable => 1, is_serializable => 1 },
  user_id             => { data_type => 'integer', is_foreign_key => 1, is_nullable => 0 },
  query_file_id       => { data_type => 'integer', is_foreign_key => 1, is_nullable => 1 },
  is_public           => { data_type => 'boolean', is_nullable => 0, default_value => 0 },
  description         => { data_type => 'text', is_nullable => 1, is_serializable => 1 },
  ord                 => { data_type => 'integer', is_nullable => 1, default_value => 0 },
  eval_num            => { data_type => 'integer', is_nullable => 1, default_value => 0 },
  #first_used_treebank => { data_type => 'integer', is_foreign_key => 1, is_nullable => 1 },
  created_at          => { data_type => 'datetime', is_nullable => 0, set_on_create => 1, set_on_update => 0 },
  last_use            => { data_type => 'datetime', is_nullable => 0, set_on_create => 1, set_on_update => 1 },
  hash => {
    data_type   => 'char',
    size        => 32,
    is_nullable => 1,
    encode_column => 1,
    encode_class  => 'Digest',
    encode_args   => {algorithm => 'MD4', format => 'hex'},
    encode_check_method => 'check_hash'}
);



__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
  query_file => 'PMLTQ::Server::Schema::Result::QueryFile', 'query_file_id'
);

__PACKAGE__->belongs_to(
  user => 'PMLTQ::Server::Schema::Result::User', 'user_id'
);

__PACKAGE__->has_many( query_record_treebanks => 'PMLTQ::Server::Schema::Result::QueryRecordTreebank', 'query_record_id', { cascade_copy => 0, cascade_delete => 1 } );

#__PACKAGE__->belongs_to(
#  treebank => 'PMLTQ::Server::Schema::Result::Treebank', 'first_used_treebank'
#);

1;
