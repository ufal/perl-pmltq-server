package PMLTQ::Server::Schema::Result::Tag;

use Mojo::Base qw/PMLTQ::Server::Schema::Result/;
use PMLTQ::Server::JSON 'json';

__PACKAGE__->table('tags');

__PACKAGE__->add_columns(
  id      => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
  name    => { data_type => 'varchar', is_nullable => 0, size => 120 },
  comment => { data_type => 'varchar', is_nullable => 1, size => 250 },
  documentation   => { data_type => 'text', is_nullable => 1, is_serializable => 1 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint('tag_name_unique', ['name']);

__PACKAGE__->has_many( treebank_tags => 'PMLTQ::Server::Schema::Result::TreebankTag', 'tag_id', { cascade_copy => 0, cascade_delete => 1 } );

__PACKAGE__->many_to_many( treebanks => 'treebank_languages', 'tag_id' );

__PACKAGE__->has_many( user_tags => 'PMLTQ::Server::Schema::Result::UserTag', 'tag_id', { cascade_copy => 0, cascade_delete => 1 } );

__PACKAGE__->many_to_many( users => 'user_tags', 'tag_id' );


=head2 list_data

Metadata for tag list

=cut

sub list_data {
  my $self = shift;

  return json {
    map { ( $_ => $self->$_ ) } qw/id name comment/ # excluding documentation in list format
  }
}

1;
