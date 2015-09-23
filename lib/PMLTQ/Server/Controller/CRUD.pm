package PMLTQ::Server::Controller::CRUD;

# ABSTRACT: Base controller for all full CRUD controllers

use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON qw/decode_json/;
use PMLTQ::Server::JSON qw(perl_key);
use Try::Tiny;
use PMLTQ::Server::Validation;
use Carp ();
use DDP;

has resultset => sub {
  $_[0]->db->resultset($_[0]->resultset_name);
};

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

  $c->app->log->debug($c->dumper($c->req->params->to_hash));

  my $params = $c->_validate_params($c->req->params->to_hash);
  $c->app->log->debug($c->dumper($params));

  my $attrs = $params->{pager} || {};
  $attrs->{order_by} = $params->{sort} if $params->{sort};

  my $resultset = $c->resultset->search($params->{filter} || undef, $attrs);
  $c->res->headers->header('X-Total-Count' => $resultset->pager->total_entries) if $params->{pager};

  my @list = $resultset->all;
  $c->render(json => \@list);
}

sub create {
  my $c = shift;

  my $input = $c->_validate($c->req->json);
  return $c->render_validation_errors unless $input;

  try {
    my $entity = $c->resultset->create($input);
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
  my $entity_id = $c->param('id');
  my $entity = $c->resultset->find($entity_id);

  unless ($entity) {
    $c->status_error({
      code => 404,
      message => $c->resultset_name . " ID '$entity_id' not found"
    });
    return;
  }

  $c->stash(entity => $entity);
}

sub get {
  my $c = shift;
  $c->render(json => $c->stash->{entity});
}

sub update {
  my $c = shift;
  my $entity = $c->stash->{entity};

  my $input = { $entity->get_columns, %{$c->req->json} };
  $input = $c->_validate($input, $entity);
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

sub remove {
  my $c = shift;
  my $entity = $c->stash->{entity};

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
      filter => sub { $c->query_filter(decode_json(shift)) },
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

1;
