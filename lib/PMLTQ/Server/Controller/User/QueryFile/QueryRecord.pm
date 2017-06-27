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

  $data->{query_file_id} ||= $c->stash->{query_file}->id;
  unless($c->db->resultset('QueryFile')->count({id => $data->{query_file_id}, user_id => $data->{user_id}})) {
    $c->status_error({
      code => 403,
      message => 'Permission denied'
    }); 
  }
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


sub update_list {
  my $c = shift;
  my $query_file = $c->entity;
  my $data_list = $c->req->json->{queries};
  my @result;
  my @queries = map {
      my $request = $_;
      $request->{query_file_id} = $query_file->id;
      my $id = $request->{id};
      # find 
      my $queryrecord = $c->resultset->find($id);
      unless ($queryrecord) {
        $c->status_error({
          code => 404,
          message => $c->resultset_name . " ID 'id' not found"
        });
        return;
      }
      $c->is_owner();
      {request => $request, record => $queryrecord}
    } @$data_list;
  for my $query (@queries) {
    my $input = { $query->{record}->get_columns, %{$query->{request}} };
    $input = $c->_validate($input, $query->{record});
    return $c->render_validation_errors unless $input;

    # Get defaults back in as validation could remove them
    $input = { $query->{record}->get_columns, %{$input} };
#    try {
       push @result, $c->resultset->recursive_update($input);
#    } catch {
#      $c->status_error({
#        code => 500,
#        message => $_
#      });
#    }
  }
  $c->render(json => {result => {queries => [map { my $q = $_; +{(map { ($q->to_json_key($_) => $q->$_) } qw/ord id user_id query_file_id/)} } @result]}});
}
1;
