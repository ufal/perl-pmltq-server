package PMLTQ::Server::Schema::Result::Manual;

use Mojo::Base qw/PMLTQ::Server::Schema::Result/;

__PACKAGE__->table('manuals');

__PACKAGE__->add_columns(
  treebank_id => { data_type => 'integer', is_nullable => 0, is_foreign_key => 1, is_serializable => 0 },
  title       => { data_type => 'varchar', is_nullable => 0, size => 250 },
  url         => { data_type => 'varchar', is_nullable => 0, size => 250 }
);

__PACKAGE__->set_primary_key('treebank_id', 'title', 'url');

__PACKAGE__->belongs_to(
    treebank => 'PMLTQ::Server::Schema::Result::Treebank',
    { id => 'treebank_id' },
);

1;
