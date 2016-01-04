package PMLTQ::Server::Schema::Result::LanguageGroup;

use Mojo::Base qw/PMLTQ::Server::Schema::Result/;

__PACKAGE__->load_components('Ordered');

__PACKAGE__->table('language_groups');

__PACKAGE__->add_columns(
  id       => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
  name     => { data_type => 'varchar', is_nullable => 0, size => 200 },
  position => { data_type => 'integer', is_nullable => 1 }
);

__PACKAGE__->position_column('position');
__PACKAGE__->null_position_value(undef);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint('language_group_name_unique', ['name']);

__PACKAGE__->has_many(
  languages => 'PMLTQ::Server::Schema::Result::Language',
  { 'foreign.language_group_id' => 'self.id' },
  { cascade_copy => 0, cascade_delete => 0 }
);

1;
