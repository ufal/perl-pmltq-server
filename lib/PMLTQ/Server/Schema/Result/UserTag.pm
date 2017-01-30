package PMLTQ::Server::Schema::Result::UserTag;

use Mojo::Base qw/PMLTQ::Server::Schema::Result/;

__PACKAGE__->table('user_tags');

__PACKAGE__->add_columns(
  user_id     => { data_type => 'integer', is_foreign_key => 1, is_nullable => 0 },
  tag_id => { data_type => 'integer', is_foreign_key => 1, is_nullable => 0 },
);

__PACKAGE__->set_primary_key('tag_id', 'user_id');

__PACKAGE__->belongs_to(tag => 'PMLTQ::Server::Schema::Result::Tag', 'tag_id');

__PACKAGE__->belongs_to(user => 'PMLTQ::Server::Schema::Result::User', 'user_id');

1;
