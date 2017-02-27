package PMLTQ::Server::Schema::Result::TreebankProvID;

use Mojo::Base qw/PMLTQ::Server::Schema::Result/;

__PACKAGE__->table('treebank_provider_ids');

__PACKAGE__->add_columns(
  treebank_id => { data_type => 'integer', is_foreign_key => 1, is_nullable => 0 },
  provider    => { data_type => 'integer', is_nullable => 0 },
  provider_id        => { data_type => 'varchar', is_nullable => 0, size => 120 },
);

__PACKAGE__->set_primary_key('provider', 'provider_id');

__PACKAGE__->belongs_to(treebank => 'PMLTQ::Server::Schema::Result::Treebank', 'treebank_id');

1;
