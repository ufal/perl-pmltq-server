package PMLTQ::Server::Schema::Result::TreebankTag;

use Mojo::Base qw/PMLTQ::Server::Schema::Result/;

__PACKAGE__->table('treebank_tags');

__PACKAGE__->add_columns(
  treebank_id => { data_type => 'integer', is_foreign_key => 1, is_nullable => 0 },
  tag_id      => { data_type => 'integer', is_foreign_key => 1, is_nullable => 0 },
);

__PACKAGE__->set_primary_key('treebank_id', 'tag_id');

__PACKAGE__->belongs_to(treebank => 'PMLTQ::Server::Schema::Result::Treebank', 'treebank_id');

__PACKAGE__->belongs_to(tag => 'PMLTQ::Server::Schema::Result::Tag', 'tag_id');

1;
