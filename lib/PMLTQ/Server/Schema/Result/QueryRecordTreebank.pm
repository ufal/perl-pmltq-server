package PMLTQ::Server::Schema::Result::QueryRecordTreebank;

use Mojo::Base qw/PMLTQ::Server::Schema::Result/;

__PACKAGE__->table('query_record_treebanks');

__PACKAGE__->add_columns(
  query_record_id     => { data_type => 'integer', is_foreign_key => 1, is_nullable => 0 },
  treebank_id => { data_type => 'integer', is_foreign_key => 1, is_nullable => 0 },
);

__PACKAGE__->set_primary_key('treebank_id', 'query_record_id');

__PACKAGE__->belongs_to(treebank => 'PMLTQ::Server::Schema::Result::Treebank', 'treebank_id');

__PACKAGE__->belongs_to(query_record => 'PMLTQ::Server::Schema::Result::QueryRecord', 'query_record_id');

1;
