package PMLTQ::Server::Schema::Result::TreebankLanguage;

use Mojo::Base qw/PMLTQ::Server::Schema::Result/;

__PACKAGE__->table('treebank_languages');

__PACKAGE__->add_columns(
  treebank_id => { data_type => 'integer', is_foreign_key => 1, is_nullable => 0 },
  language_id => { data_type => 'integer', is_foreign_key => 1, is_nullable => 0 },
);

__PACKAGE__->set_primary_key('treebank_id', 'language_id');

__PACKAGE__->belongs_to(treebank => 'PMLTQ::Server::Schema::Result::Treebank', 'treebank_id');

__PACKAGE__->belongs_to(language => 'PMLTQ::Server::Schema::Result::Language', 'language_id');

1;
