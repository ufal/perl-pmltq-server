package PMLTQ::Server::Schema::Result::DataSource;

use Mojo::Base qw/PMLTQ::Server::Schema::Result/;

__PACKAGE__->table('data_sources');

__PACKAGE__->add_columns(
  treebank_id => { data_type => 'integer', is_nullable => 0, is_foreign_key => 1, is_serializable => 0 },
  layer       => { data_type => 'varchar', is_nullable => 0, size => 250 },
  path        => { data_type => 'varchar', is_nullable => 0, size => 250 }
);

__PACKAGE__->set_primary_key('treebank_id', 'layer');

__PACKAGE__->belongs_to(
  treebank => 'PMLTQ::Server::Schema::Result::Treebank', 'treebank_id'
);

1;
