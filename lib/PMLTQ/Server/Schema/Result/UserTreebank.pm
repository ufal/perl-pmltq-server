package PMLTQ::Server::Schema::Result::UserTreebank;

use Mojo::Base qw/PMLTQ::Server::Schema::Result/;

__PACKAGE__->table('user_treebanks');

__PACKAGE__->add_columns(
  user_id     => { data_type => 'integer', is_foreign_key => 1, is_nullable => 0 },
  treebank_id => { data_type => 'integer', is_foreign_key => 1, is_nullable => 0 },
);

__PACKAGE__->set_primary_key('treebank_id', 'user_id');

__PACKAGE__->belongs_to(treebank => 'PMLTQ::Server::Schema::Result::Treebank', 'treebank_id');

__PACKAGE__->belongs_to(user => 'PMLTQ::Server::Schema::Result::User', 'user_id');

1;
