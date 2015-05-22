package PMLTQ::Server::Controller::Treebank;

# ABSTRACT: Handling everything related to treebanks

use Mojo::Base 'Mojolicious::Controller';
use Mango::BSON 'bson_oid';
use Mojo::Asset::Memory;
use Mojo::Asset::File;
use Mojo::JSON;
use PMLTQ::Common;
use PMLTQ::Server::Validation;

=head1 METHODS

=head2 list

=cut

sub list {
  my $c = shift;

  $c->mandel->collection('treebank')->all(sub {
    my($collection, $err, $treebanks) = @_;

    $c->render(json => [ map {
      my $data = $_->list_data;
      $data->{access} = $_->accessible($c->current_user) ? Mojo::JSON->true : Mojo::JSON->false;
      $data
    } @$treebanks ]);
  });

  $c->render_later;
}

=head2 initialize

Bridge for other routes. Saves current treebank to stash under 'tb' key.

=cut

sub initialize {
  my $c = shift;

  my $id = $c->param('treebank_id');
  $c->mandel->collection('treebank')->search({_id => bson_oid($id)})->single(sub {
    my ($collection, $err, $tb) = @_;

    return $c->status_error({
      code => 404,
      message => "Treebank '$id' not found"
    }) unless $tb;

    return $c->status_error({
      code => 500,
      message => "Database error: $err"
    }) if $err;

    unless ($tb->accessible($c->current_user)) {
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

      unless ($tb->accessible($c->current_user)) {
        return $c->status_error({
          code => 403,
          message => 'Authorization failed, you cannot access this treebank'
        });
      }
    }

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
  my $metadata = $tb->metadata;
  $metadata->{access} = $tb->accessible($c->current_user) ? Mojo::JSON->true : Mojo::JSON->false;

  $c->render(json => $metadata);
}

sub suggest {
  my $c = shift;

  return $c->status_error({
    code => 500,
    message => "Suggest service not available or not defined"
  }) unless $c->config->{nodes_to_query_service};

  my $input = $c->_validate_suggest($c->req->json);

  return $c->render_validation_errors unless $input;

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
    $f =~ s{(#.*$)}{};
    $path = $tb->resolve_data_path($f, $c->config->{data_dir});
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
        $c->render(json => {
          query => $res->text
        });
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

sub _validate_suggest {
  my ($c, $data) = @_;

  my $rules = {
    fields => [qw/ids vars/],
    checks => [
      ids => [is_required('Ids not specified'),
              is_a('ARRAY', 'Ids have to be an array'),
              sub {
                my $ids = shift;
                return "Ids array is empty" unless @$ids > 0;
                for my $node_id (@$ids) {
                  return "'$node_id' in not a valid ID" unless $node_id =~ m{^(\d+)/.+[+@].+$}
                }
              }],
      vars => is_a('ARRAY', 'Vars have to be an array')
    ]
  };

  $c->do_validation($rules, $data);
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
