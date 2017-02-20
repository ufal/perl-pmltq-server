package PMLTQ::Server::Controller::Admin::Tag;

# ABSTRACT: Managing tags in administration

use Mojo::Base 'PMLTQ::Server::Controller::CRUD';
use PMLTQ::Server::Validation;

has resultset_name => 'Tag';

has search_fields => sub { [qw/name comment/] };

sub _validate {
  my ($c, $tag_data) = @_;

  my $rules = {
    fields => [qw/id name comment documentation/],
    filters => [
      [qw/name comment/] => filter(qw/trim strip/),
    ],
    checks => [
      name => [is_required(), is_long_at_most(120), is_unique($c->resultset, 'id', 'tag name already exists')],
      comment => is_long_at_most(250),
    ]
  };

  return $c->do_validation($rules, $tag_data);
}


1;
