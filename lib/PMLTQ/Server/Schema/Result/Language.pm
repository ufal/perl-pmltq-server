package PMLTQ::Server::Schema::Result::Language;

use Mojo::Base qw/PMLTQ::Server::Schema::Result/;

__PACKAGE__->load_components('Ordered');

__PACKAGE__->table('languages');

__PACKAGE__->add_columns(
  id                => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
  language_group_id => { data_type => 'integer', is_foreign_key => 1, is_nullable => 1 },
  code              => { data_type => 'varchar', is_nullable => 0, size => 10 },
  name              => { data_type => 'varchar', is_nullable => 0, size => 120 },
  position          => { data_type => 'integer', is_nullable => 1 }
);

__PACKAGE__->position_column('position');
__PACKAGE__->grouping_column('language_group_id');
__PACKAGE__->null_position_value(undef);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint('language_code_unique', ['code']);

__PACKAGE__->belongs_to(
  'language_group',
  'PMLTQ::Server::Schema::Result::LanguageGroup',
  { id => 'language_group_id' },
  {
    is_deferrable => 1,
    join_type     => 'LEFT',
  },
);

__PACKAGE__->has_many( treebank_languages => 'PMLTQ::Server::Schema::Result::TreebankLanguage', 'language_id' );

__PACKAGE__->many_to_many( treebanks => 'treebank_languages', 'language_id' );

1;
