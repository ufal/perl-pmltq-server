package PMLTQ::Server::Schema::Result::QueryFile;

use Mojo::Base qw/PMLTQ::Server::Schema::Result/;

use PMLTQ::Server::JSON 'json';

__PACKAGE__->table('query_files');

__PACKAGE__->load_components('InflateColumn::DateTime', 'TimeStamp');

__PACKAGE__->add_columns(
  id          => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
  name        => { data_type => 'varchar', is_nullable => 0, size => 120 },
  user_id     => { data_type => 'integer', is_foreign_key => 1, is_nullable => 1 },
  is_public   => { data_type => 'boolean', is_nullable => 0, default_value => 0 },
  description => { data_type => 'text', is_nullable => 1, is_serializable => 1 },
  created_at  => { data_type => 'datetime', is_nullable => 0, set_on_create => 1, set_on_update => 0 },
  last_use    => { data_type => 'datetime', is_nullable => 0, set_on_create => 1, set_on_update => 1 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint('query_file_name_unique', ['name', 'user_id']);

__PACKAGE__->belongs_to(
  user => 'PMLTQ::Server::Schema::Result::User', 'user_id'
);

__PACKAGE__->has_many(
  queries => 'PMLTQ::Server::Schema::Result::QueryRecord',
  { 'foreign.query_file_id' => 'self.id' },
  { cascade_copy => 0, cascade_delete => 1 },
);

sub TO_JSON {
   my $self = shift;

   return {
      (map { ($self->to_json_key($_) => [$self->$_]) } qw/queries/),
      %{ $self->next::method },
   }
}


sub list_data {
  my $self = shift;

  return json {
    (map { ( $_ => $self->$_ ) } qw/id name user_id created_at last_use is_public description/),
    $self->to_json_key('queries') => [$self->queries()->all]
  }
}

sub metadata {
   my $self = shift;

  return json {
    (map { ( $_ => $self->$_ ) } qw/id name user_id created_at last_use/),
  }
}
1;
