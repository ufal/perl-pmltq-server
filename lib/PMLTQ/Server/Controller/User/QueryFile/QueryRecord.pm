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
  my ($c, $data, $current) = @_;

  my $rules = {
    fields => [qw/query name ord/],
    filters => [
      [qw/name/] => filter(qw/trim strip/),
    ],
    checks => [
      name => [is_long_at_most(120)],
      ord  => is_integer()
    ]
  };
  $data->{ord} //= time();

  if($current) { # on query update
    $data->{treebanks} = [] unless $current->query eq $data->{query};
  }

  $data = $c->do_validation($rules, $data);
  $data->{hash} = collapse_query()->($data->{query});
  $data->{user_id} = $c->current_user->id;
  $data->{query_file_id} = $c->stash->{query_file}->id;

  return $data;
}

sub is_owner {
  my $c = shift;

  unless ($c->entity->user_id == $c->current_user->id) {
    $c->status_error({
      code => 403,
      message => 'Permission denied'
    });

    return;
  }

  return 1;
}

1;
