package PMLTQ::Server::Controller::User::QueryFile;

# ABSTRACT: Managing query files

use Mojo::Base 'PMLTQ::Server::Controller::CRUD';
use PMLTQ::Server::Validation;

has resultset_name => 'QueryFile';

sub _validate {
  my ($c, $data) = @_;
  my $rules = {
    fields => [qw/name/],
    filters => [
      [qw/name/] => filter(qw/trim strip/),
    ],
    checks => [
      name => [is_required(), is_long_at_most(120), is_unique($c->resultset, 'id', 'filename already exists', ['user_id'])],
    ]
  };

  $data->{user_id} = $c->current_user->id;
  $data = $c->do_validation($rules, $data);

  return $data;
}

1;
