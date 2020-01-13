package PMLTQ::Server::Controller::CRUD;

# ABSTRACT: Base controller for all full CRUD controllers

use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON qw/from_json/;
use PMLTQ::Server::JSON qw(perl_key);
use Try::Tiny;
use PMLTQ::Server::Validation;
use Encode 'decode';
use Carp ();

has resultset => sub {
  $_[0]->db->resultset($_[0]->resultset_name);
};

has 'search_fields';

sub new {
  my $c = shift->SUPER::new(@_);
  Carp::croak 'resultset name not specified' unless $c->resultset_name;
  return $c;
}

=head1 METHODS

=head2 initialize

Bridge for other routes. Saves current treebank to stash under 'tb' key.

=cut

sub list {
  my $c = shift;

  my $params = $c->_validate_params($c->req->params->to_hash);
  my $attrs = $params->{pager} || {};
  $attrs->{order_by} = $params->{sort} if $params->{sort};

  my $filter = $params->{filter};
  if ($c->search_fields && $filter && $filter->{q}) {
    my $q = delete $filter->{q};
    my @search = map { ($_ => {ilike => "%$q%"}) } @{$c->search_fields};
    if ($filter->{-or}) {
      push @{$filter->{-or}}, @search;
    } else {
      $filter->{-or} = \@search
    }
  }

  my $resultset = $c->resultset->search($filter || undef, $attrs);
  $c->res->headers->header('X-Total-Count' => $resultset->pager->total_entries) if $params->{pager};

  my @list = $resultset->all;
  $c->render(json => \@list);
}

sub create {
  my $c = shift;

  my $input = $c->_validate($c->req->json);
  return $c->render_validation_errors unless $input;

  try {
    my $entity = $c->resultset->recursive_update($input);
    $c->render(json => $entity);
  } catch {
    $c->status_error({
      code => 500,
      message => $_
    });
  }
}

sub find {
  my $c = shift;
  my $entity_id_name = $c->stash->{entity_id_name};
  my $entity_id = $c->param($entity_id_name);
  my $entity = $c->resultset->find($entity_id);

  unless ($entity) {
    $c->status_error({
      code => 404,
      message => $c->resultset_name . " ID '$entity_id' not found"
    });
    return;
  }

  $c->entity($entity);
}

sub entity {
  my $c = shift;

  my $entity_name = $c->stash->{entity_name};
  return $c->stash->{$entity_name} unless (@_);
  $c->stash($entity_name, @_);
}

sub get {
  my $c = shift;
  $c->render(json => $c->entity);
}

sub update {
  my $c = shift;
  my $entity = $c->entity;

  # Factor the validation some day
  # Get defaults here for validation
  my $input = { $entity->get_columns, %{$c->req->json} };
  $input = $c->_validate($input, $entity);
  return $c->render_validation_errors unless $input;

  # Get defaults back in as validation could remove them
  my $columns_info = $entity->result_source->columns_info([$entity->result_source->columns]);
  my %columns = $entity->get_columns;

  # remove encoded fields
  delete $columns{$_} for grep {$columns_info->{$_}->{encode_column}} keys %$columns_info;

  $input = { %columns, %{$input} };

  try {
    my $entity = $c->resultset->recursive_update($input);
    $c->render(json => $entity);
  } catch {
    $c->status_error({
      code => 500,
      message => $_
    });
  }
}

sub update_list {
  my $c = shift;
  $c->status_error({
    code => 403,
    message => 'Updating list is not allowed'
  });
}

sub remove {
  my $c = shift;
  my $entity = $c->entity;

  try {
    $entity->delete();
    $c->render(json => $entity);
  } catch {
    $c->status_error({
      code => 500,
      message => $_
    });
  }
}

sub _validate_params {
  my ($c, $params) = @_;

  state $rules = {
    fields => [qw/filter pager sort/],
    filters => [
      filter => sub { $c->query_filter(from_json(shift)) },
      pager => sub { my @pager = split /,/, shift; { page => $pager[0] || 1 , rows => $pager[1] || 30 } },
      sort => sub { my @sort = split /,/, shift; my %sort = (); $sort{'-' . lc $sort[1]} = perl_key($sort[0]); \%sort }
    ],
    checks => [
      filter => is_hash()
    ]
  };

  return $c->do_validation($rules, $params);
}

sub _validate { }

sub true {return 1}

1;
