package PMLTQ::Server::Controller::User::QueryFile::QueryRecord;

# ABSTRACT: Managing query files

use Mojo::Base 'PMLTQ::Server::Controller::CRUD';
use PMLTQ::Server::Validation;

has resultset_name => 'QueryRecord';

has resultset => sub {
  my $c = shift;
  my $qf = $c->stash->{query_file};
  $c->db->resultset($c->resultset_name)->search_rs({query_file_id => $qf->id});
};

sub _validate {
  my ($c, $data) = @_;

  my $rules = {
    fields => [qw/query name/],
    filters => [
      [qw/name/] => filter(qw/trim strip/),
    ],
    checks => [
      name => [is_long_at_most(120)],
    ]
  };

  $data = $c->do_validation($rules, $data);
  $data->{user_id} = $c->current_user->id;
  $data->{query_file_id} = $c->stash->{query_file}->id;

  return $data;
}

1;
