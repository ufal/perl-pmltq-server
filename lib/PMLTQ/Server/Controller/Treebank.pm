package PMLTQ::Server::Controller::Treebank;

# ABSTRACT: Handling everything related to treebanks

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Asset::Memory;
use Mojo::Asset::File;
use PMLTQ::Common;
use PMLTQ::Server::Validation;

=head1 METHODS

=head2 list

=cut

sub list {
  my $c = shift;

  my @treebanks = map { $_->list_data } $c->public_treebanks->all;
  $c->render(json => \@treebanks);
}

=head2 initialize

Bridge for other routes. Saves current treebank to stash under 'tb' key.

=cut

sub initialize_single {
  my $c = shift;

  my $id = $c->param('treebank_id');
  my $search = { id => $id };
  $search = { name => $id } if ($id !~ m/^\d+$/);
  my $tb = $c->db->resultset('Treebank')->single($search);

  unless ($tb) {
    $c->status_error({
      code => 404,
      message => "Treebank '$id' not found"
    });
    return;
  }

  unless ($tb->accessible($c->current_user)) {
    unless ($c->current_user) {
      return unless $c->basic_auth({
        invalid => sub {
          any => sub {
            my $ctrl = shift;
            $ctrl->res->headers->remove('WWW-Authenticate');
            $ctrl->status_error({
              code => 401,
              message => 'Authentication is required to see this treebank'
            });
          }
        }
      });
    }

    if ($c->current_user && !$tb->accessible($c->current_user)) {
      $c->status_error({
        code => 403,
        message => 'Authorization failed, you cannot access this treebank'
      });
      return;
    }
  }

  $c->stash(tb => $tb);
}

=head2 metadata

=cut

sub metadata {
  my $c = shift;

  my $tb = $c->stash('tb');
  $c->render(json => $tb->metadata);
}

sub data {
  my $c = shift;

  my $tb = $c->stash('tb');
  my $file = $c->param('file');
  $file =~ s{#.*}{};

  return $c->status_error({
    code => 400,
    message => "File parameter not specified"
  }) unless $file;

  my $path = $tb->resolve_data_path($file, $c->config->{data_dir});

  my $err_message;
  unless (defined $path && -e $path) {
    $err_message = "Object $file not found!";
  }
  elsif (not(-r $path)) {
    $err_message = "Object $file : $path not readable!\nPlease notify PML-TQ administrator!"
  }
  else {
    #$c->res->headers->content_type('text/plain');
    $c->reply->asset(Mojo::Asset::File->new(path => $path));
    return;
  }

  if ($err_message) {
    $c->status_error({
      code => 404,
      message => $err_message
    });
    return;
  }
}

sub node {
  my $c = shift;

  my $tb = $c->stash('tb');
  my $idx = $c->param('idx');

  return $c->status_error({
    code => 400,
    message => "Idx parameter not specified"
  }) unless $idx;

  my ($f) = eval {
    my $evaluator = $tb->get_evaluator;
    $evaluator->idx_to_pos([$idx]);
  };

  if ($f) {
    $c->render(json => {
      node => $f
    });
  } else {
    $c->status_error({
      code => 404,
      message => "Error resolving $idx: $@"
    });
  }
}

sub schema {
  my $c = shift;

  my $tb = $c->stash('tb');
  my $name = $c->param('name');

  return $c->status_error({
    code => 400,
    message => "Name parameter not specified"
  }) unless $name;

  my $results = eval {
    my $evaluator = $tb->get_evaluator;
    $evaluator->run_sql_query(
      qq(SELECT "schema" FROM "#PML" WHERE "root" = ? ),
      {
        MaxRows => 1,
        RaiseError => 1,
        LongReadLen => 512*1024,
        Bind => [$name]
      });
  };

  return $c->status_error({
    code => 500,
    message => "Evaluator error: $@"
  }) if $@;

  if (ref($results) and ref($results->[0]) and $results->[0][0]) {
    $c->res->headers->content_type('application/octet-stream');
    $c->reply->asset(Mojo::Asset::Memory->new->add_chunk($results->[0][0]));
  } else {
    $c->status_error({
      code => 400,
      message => "Schema '$name' not found"
    })
  }
}

sub type {
  my $c = shift;

  my $tb = $c->stash('tb');
  my $type = $c->param('type');

  return $c->status_error({
    code => 400,
    message => "Type parameter not specified"
  }) unless $type;

  my $name = eval {
    my $evaluator = $tb->get_evaluator;
    $evaluator->get_schema_name_for($type)
  };

  $name //= '';

  $c->render(json => {
    name => $name
  });
}

sub node_types {
  my $c = shift;

  my $tb = $c->stash('tb');
  my $layer = $c->param('layer');

  my $types = eval{
    my $evaluator = $tb->get_evaluator;
    $evaluator->get_node_types($layer || ());
  };

  $c->render(json => {
    types => $types||[]
  });
}

sub relations {
  my $c = shift;

  my $tb = $c->stash('tb');
  my $type = $c->param('type');
  my $rel_cat = $c->param('category');

  my $evaluator = eval { $tb->get_evaluator; };
  return $c->status_error({
    code => 500,
    message => "Evaluator initialize failed: $@"
  }) if $@;

  my $relations;
  if ($rel_cat eq 'implementation') {
    $relations = $evaluator->get_user_defined_relations($type);
  } elsif ($rel_cat eq 'pmlrf') {
    $relations = $evaluator->get_pmlrf_relations($type);
  } else {
    $relations = $evaluator->get_specific_relations($type);
  }

  $c->render(json => {
    relations => $relations
  });
}

sub relation_target_types {
  my $c = shift;

  my $tb = $c->stash('tb');
  my $type = $c->param('type');
  my $category = $c->param('category');

  my $evaluator = eval { $tb->get_evaluator; };
  return $c->status_error({
    code => 500,
    message => "Evaluator initialize failed: $@"
  }) if $@;

  my @map;
  my %map;
  if ($type) {
    my @maps;
    if (!$category or $category eq 'pmlrf') {
      push @maps, $evaluator->get_pmlrf_relation_map_for_type($type);
    }
    if (!$category or $category eq 'implementation') {
      push @maps, $evaluator->get_user_defined_relation_map_for_type($type);
    }
    for my $map (@maps) {
      for my $rel (sort keys %$map) {
        my $target = $map->{$rel};
        if (defined $target) {
          push @map,[$type,$rel,$target->[2]];
        }
      }
    }
  } else {
    my @maps;
    if (!$category or $category eq 'pmlrf') {
      push @maps, $evaluator->get_pmlrf_relation_map();
    }
    if (!$category or $category eq 'implementation') {
      push @maps, $evaluator->get_user_defined_relation_map();
    }
    for my $map (@maps) {
      for my $node_type (sort keys %$map) {
        my $map2 = $map->{$node_type};
        if ($map2) {
          for my $rel (sort keys %$map2) {
            my $target = $map2->{$rel};
            if (defined $target) {
              push @map,[$node_type,$rel,$target->[2]];
            }
          }
        }
      }
    }
  }

  $c->render(json => {
    map => \@map
  });
}


1;
