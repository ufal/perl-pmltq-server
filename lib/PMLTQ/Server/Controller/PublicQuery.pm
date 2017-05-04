package PMLTQ::Server::Controller::PublicQuery;

# ABSTRACT: Handling everything related to query sharing

use Mojo::Base 'Mojolicious::Controller';
use PMLTQ::Common;
use PMLTQ::Server::Validation;

sub initialize_single {
  my $c = shift;
  my $query_file_id = $c->param('file');
  my $user_id = $c->param('user_id');
  my $query_file;

  if($query_file_id eq 'public') {
    $query_file = $c->get_public_file($user_id);
  } else {
    my $search = { id => $query_file_id, user_id => $user_id, ($c->current_user && $c->current_user->id == $user_id) ? () : (is_public => 1) };
    $query_file = $c->db->resultset('QueryFile')->single($search);
  }
  unless ($query_file) {
    $c->status_error({
      code => 404,
      message => "Query list '$query_file_id' not found"
    });
    return;
  }

  $c->stash(queryfile => $query_file);
}

sub get {
  my $c = shift;

  my $qf = $c->stash('queryfile');
  $c->render(json => $qf);
}

sub get_public_file {
  my $c = shift;
  my $user_id = shift;
  my @queries = $c->db->resultset('QueryRecord')->search_rs({user_id => $user_id, is_public => 1})->all;
  return {
    name => 'PUBLIC',
    id => 'public',
    user_id => $user_id,
    userId => $user_id, # hack
    queries => \@queries
  }
}

sub list {
  my $c = shift;
  my @public_lists = $c->db->resultset('QueryFile')->search_rs({is_public => 1})->all;
  my %public_queries_users = map {$_->user_id => {}} $c->db->resultset('QueryRecord')->search_rs({is_public => 1})->all;
  my %tree = (%public_queries_users, map {$_->user_id => {}} @public_lists);
  for my $user_id (keys %tree) {
    $tree{$user_id}->{name} = $c->db->resultset('User')->single({id => $user_id})->name;
    $tree{$user_id}->{id} = $user_id;
    $tree{$user_id}->{files} = [
      (map { $_->metadata} grep {$_->user_id == $user_id} @public_lists), 
      $public_queries_users{$user_id}
        ? ({
            name => 'PUBLIC',
            id => 'public',
            user_id => $user_id,
            userId => $user_id, # hack
          }) 
        : ()];
  }
  $c->render(json => [values %tree]);
}

1;