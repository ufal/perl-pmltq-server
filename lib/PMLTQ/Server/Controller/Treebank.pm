package PMLTQ::Server::Controller::Treebank;

# ABSTRACT: Handling everything related to treebanks

use Mojo::Base 'Mojolicious::Controller';
use Mango::BSON 'bson_oid';
use Mojo::Asset::Memory;

=head1 METHODS

=head2 list

=cut

sub list {
  my $c = shift;

  $c->mandel->collection('treebank')->all(sub {
    my($collection, $err, $treebanks) = @_;

    $c->render(json => [ map {
      my $m = $_->metadata;
      $m->{url} = $c->url_for('treebank', treebank => $_->name);
      $m
    } @$treebanks ]);
  });

  $c->render_later;
}

=head2 initialize

Bridge for other routes. Saves current treebank to stash under 'tb' key.

=cut

sub initialize {
  my $c = shift;

  my $tb_name = $c->param('treebank');
  $c->mandel->collection('treebank')->search({name => $tb_name})->single(sub {
    my ($collection, $err, $tb) = @_;

    return $c->status_error({
      code => 404,
      message => "Treebank '$tb_name' not found"
    }) unless $tb;

    return $c->status_error({
      code => 500,
      message => "Database error: $err"
    }) if $err;

    $c->stash(tb => $tb);
    $c->continue;
  });

  return undef;
}

=head2 metadata

=cut

sub metadata {
  my $c = shift;

  my $tb = $c->stash('tb');

  $c->render(json => $tb->metadata);
}

sub suggest {
  my $c = shift;

  my $input = $c->res->json;

  return $c->status_error({
    code => 500,
    message => "Suggest service not available or not defined"
  }) unless $c->config->{nodes_to_query_service};

  return $c->status_error({
    code => 400,
    message => "Node ids not specified"
  }) if !$input->{ids} || ref($input->{ids}) ne 'ARRAY';


  my $tb = $c->stash('tb');
  my @f = eval {
    my $evaluator = $tb->get_evaluator;
    $evaluator->idx_to_pos($input->{ids}, 1);
  };

  return $c->status_error({
    code => 500,
    message => "Evaluator initialize failed: $@"
  }) if $@;

  foreach my $f (@f) {
    my $path;
    $path = $tb->resolve_data_path($f);
    return $c->status_error({
      code => 404,
      message => "File $f not found"
    }) unless defined $path;
  }

  my $url = Mojo::URL->new($c->config->{nodes_to_query_service});
  $url->query(p => join('|', @f), ($input->{vars} ? (r => $input->{vars}) : ()));
  $c->app->ua->get($url => sub {
      my ($ua, $tx) = @_;
      if (my $res = $tx->success) {
        $c->tx->res($res); # TODO: convert to some kind of json
        $c->rendered($res->code);
      } else {
        my ($err, $code) = $tx->error;
        $c->status_error({
          code => $code||500,
          message => ref $err ? $err : "$err"
        })
      }
  });

  $c->render_later;
}

sub data {
  my $c = shift;

  my $tb = $c->stash('tb');
  my $file = $c->param('file');

  return $c->status_error({
    code => 400,
    message => "File parameter not specified"
  }) unless $file;

  my $path = $tb->resolve_data_path($file);

  my $err_message;
  unless (defined $path) {
    $err_message = "Object $file not found!";
  } elsif (!(-r $path)) {
    $err_message = "Object $file not readable!\nPlease notify PML-TQ administrator!"
  } else {
    $c->res->headers->content_type('text/plain');
    $c->reply->static($path);
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
