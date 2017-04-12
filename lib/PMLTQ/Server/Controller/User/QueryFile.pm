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


=head1 METHODS

=head2 list query file for current user

=cut

sub list {
  my $c = shift;
  my $showhist = $c->req->param('history_list') // 0;

  my @query_files = grep { $showhist || !($_->{name} eq 'HISTORY') } map {$_->list_data} $c->db->resultset('QueryFile')->search_rs({user_id => $c->current_user->id})->all;
  $c->render(json => \@query_files);
}

1;
