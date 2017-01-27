package PMLTQ::Server::Schema::Result::Treebank;

use Mojo::Base qw/PMLTQ::Server::Schema::Result/;

use PMLTQ::Server::JSON 'json';
use PMLTQ::SQLEvaluator;
use Treex::PML;
use File::Spec;
use Treex::PML::Schema;
use PMLTQ::Common;
use URI;

__PACKAGE__->table('treebanks');

__PACKAGE__->load_components('InflateColumn::DateTime', 'TimeStamp');

__PACKAGE__->add_columns(
  id            => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
  server_id     => { data_type => 'integer', is_foreign_key => 1, is_nullable => 0 },
  database      => { data_type => 'varchar', is_nullable => 0, size => 120 },
  name          => { data_type => 'varchar', is_nullable => 0, size => 120 },
  title         => { data_type => 'varchar', is_nullable => 0, size => 250 },
  homepage      => { data_type => 'varchar', is_nullable => 1, size => 250 },
  handle        => { data_type => 'varchar', is_nullable => 1, size => 250 },
  description   => { data_type => 'text', is_nullable => 1, is_serializable => 1 },
  is_public     => { data_type => 'boolean', is_nullable => 0, default_value => 1 },
  is_free       => { data_type => 'boolean', is_nullable => 0, default_value => 0 },
  is_all_logged => { data_type => 'boolean', is_nullable => 0, default_value => 1 },
  is_featured   => { data_type => 'boolean', is_nullable => 0, default_value => 0 },
  created_at    => { data_type => 'datetime', is_nullable => 0, set_on_create => 1, set_on_update => 0 },
  last_modified => { data_type => 'datetime', is_nullable => 0, set_on_create => 1, set_on_update => 1 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint('treebank_name_unique', ['name']);

__PACKAGE__->belongs_to(
  server => 'PMLTQ::Server::Schema::Result::Server', 'server_id'
);

__PACKAGE__->has_many(
  manuals => 'PMLTQ::Server::Schema::Result::Manual',
  'treebank_id',
  { cascade_copy => 1, cascade_delete => 1, cascade_update => 1 },
);

__PACKAGE__->has_many(
  data_sources => 'PMLTQ::Server::Schema::Result::DataSource',
  'treebank_id',
  { cascade_copy => 1, cascade_delete => 1, cascade_update => 1 },
);

__PACKAGE__->has_many(
  users => 'PMLTQ::Server::Schema::Result::UserTreebank',
  'treebank_id',
  { cascade_copy => 0, cascade_delete => 1 },
);

__PACKAGE__->has_many(
  treebank_languages => 'PMLTQ::Server::Schema::Result::TreebankLanguage',
  'treebank_id',
  { cascade_copy => 1, cascade_delete => 1, cascade_update => 1 },
);

__PACKAGE__->many_to_many( languages => 'treebank_languages', 'language' );

__PACKAGE__->has_many(
  treebank_tags => 'PMLTQ::Server::Schema::Result::TreebankTag',
  'treebank_id',
  { cascade_copy => 1, cascade_delete => 1, cascade_update => 1 },
);

__PACKAGE__->many_to_many( tags => 'treebank_tags', 'tag' );


# __PACKAGE__->has_many( user_treebanks => 'PMLTQ::Server::Schema::Result::UserTreebank',  'user_id',  { cascade_copy => 0, cascade_delete => 1 });

#__PACKAGE__->many_to_many( users => 'user_treebanks', 'treebank_id' );


sub TO_JSON {
   my $self = shift;

   return {
      (map { ($self->to_json_key($_) => [$self->$_]) } qw/data_sources languages manuals tags/),
      %{ $self->next::method },
   }
}

=head1 METHODS

=head2 metadata

=cut

sub metadata {
  my $self = shift;

  my $ev = $self->get_evaluator();

  my $schema_names = $ev->get_schema_names();
  my $node_types = $ev->get_node_types();
  my %node_types = map { $_ => $ev->get_node_types($_) } @$schema_names;

  my $relations = {
    standard => \@{PMLTQ::Common::standard_relations()},
    pml => { },
    user => { },
  };

  foreach my $type (@$node_types) {
    my $types = $ev->get_pmlrf_relations($type);
    if (@$types) {
      $relations->{pml}->{$type} = $types;
    }
  }

  foreach my $type (@$node_types) {
    my $types = $ev->get_user_defined_relations($type);
    if (@$types) {
      $relations->{user}->{$type} = $types;
    }
  }

  my %attributes = map {
    my @res;
    my $type = $_;
    my $decl = $ev->get_decl_for($_);
    if ($decl) {
      @res = map { my $t = $_; $t=~s{#content}{content()}g; $t } $decl->get_paths_to_atoms({ no_childnodes => 1});
      if (@{PMLTQ::Common::GetElementNamesForDecl($decl)}) {
        unshift @res, 'name()';
      }
    }
    @res ? ($type => \@res) : ()
  } @$node_types;

  my $list_data = $self->list_data();

  return json {
    schemas => $ev->get_schema_names(),
    node_types => \%node_types,
    relations => $relations,
    attributes => \%attributes,
    doc => $self->generate_doc,
    %{$list_data}
  }
}

=head2 list_data

Metadata for treebank list

=cut

sub list_data {
  my $self = shift;

  return json {
    tags => [$self->tags()->all],
    languages => [$self->languages()->all],
    map { ( $_ => $self->$_ ) } qw/id name title description homepage is_public is_free is_featured handle/
  }
}

=head2 accessible

Check if the user has access to the treebank.

=cut

sub accessible {
  my ($self, $user) = @_;

  return 1 if $self->is_free;
  return 1 if $user && $self->is_all_logged;
  return $user->can_access_treebank($self->id,[$self->tags()->all]) if $user;
  return 0;
}


=head2 get_evaluator

Instantiate L<PMLTQ::SQLEvaluator> based on treebank settings, takes no
parameters.

  $evaluator  = $treebank->get_evaluator;
  $evaluator2 = $treebank->get_evaluator;

Note: C<$evaluator> and C<$evaluator2> are actually the same instances.

=cut

my $evaluators = {};

sub get_evaluator {
  my $self = shift;
  my $key = $self->id;

  unless ($evaluators->{$key}) {
    my $server = $self->server;
    my $evaluator = PMLTQ::SQLEvaluator->new(undef, {
      connect => {
        driver => 'Pg',
        host => $server->host,
        port => $server->port,
        database => $self->database,
        username => $server->username,
        password => $server->password
      }
    });
    $evaluator->connect();
    $evaluators->{$key} = $evaluator;
  }

  return $evaluators->{$key};
}

=head2 record_history

Saves a query to the history for the current user.

  $tb->record_history($history_key, $query, $user, $cb);

=cut

# sub record_history {
#   my ($self, $history_key, $query, $user, $cb) = @_;

#   return unless $query and $history_key;

#   my $rec = $self->connection->collection('history')->create({
#     history_key => $history_key,
#     query => $query,
#   });
#   $rec->user($user->id) if $user;
#   $rec->treebank($self->id);

#   if ($cb) {
#     $rec->save($cb)
#   } else {
#     $rec->save;
#     return $rec;
#   }
# }

=head2 run_query

Will do a actual search on the treebank using the L<PMLTQ::SQLEvaluator>.

=cut

sub run_query {
  my $self = shift;
  my %opts = (@_);

  $opts{limit} //= 100;
  $opts{filter} //= 1;

  my ($evaluator, $sth);
  eval {
    $evaluator = $self->get_evaluator;
    my $no_distinct = ($opts{limit}<=10_000) ? 1 : 0;
    my $qt = $evaluator->prepare_query($opts{query},{
      node_limit => $opts{limit},
      row_limit => $opts{limit},
      select_first => $opts{select_first},
      use_cursor => $opts{use_cursor},
      timeout => $opts{timeout},
      debug_sql => $opts{debug},
      no_filters => !$opts{filter},
      no_distinct => $no_distinct,
      node_IDs => 1,
    });
    undef $qt;
    $sth = $evaluator->run({
      node_limit => $opts{limit},
      row_limit => $opts{limit},
      timeout => $opts{timeout},
      use_cursor => $opts{use_cursor},
      return_sth => 1,
    });
  };
  my $err = $@;
  if ($err) {
    $evaluator->close_cursor() if $evaluator && $opts{use_cursor};

    die $err;
  }
  return ($sth,$evaluator->{returns_nodes},$evaluator->get_query_nodes,$evaluator);
}

=head2 locate_file

Path to the files is actually stored in the database. This involves running some
sql queries.

=cut

sub locate_file {
  my ($self, $f) = @_;
  my $evaluator = $self->get_evaluator();
  my $schemas = $evaluator->run_sql_query(qq{SELECT "root","data_dir","schema_file" FROM "#PML"},
                                          { RaiseError=>1 });
  for my $schema (@$schemas) {
    for my $what ('__#files','__#references') {
      my $n = $schema->[0].$what;
      next if $n=~/"/;          # just for sure
      # print STDERR "testing: $what $n $f\n";
      my $count = $evaluator->run_sql_query(qq{SELECT count(1) FROM "$n" WHERE "file"=?}, {
          RaiseError=>1,
          Bind=>[ $f ],
        });
      if ($count->[0][0]) {
        return ($schema->[0], $schema->[1]);
      }
    }
  }
  my $basename = $f; $basename =~ s{.*/}{};
  for my $schema (@$schemas) {
    my $schema_filename = $schema->[2];
    if ($schema_filename eq $f or
        $schema_filename eq $basename or
        ($schema_filename =~ s{.*/}{} and ($schema_filename eq $basename or $schema_filename eq $f))) {
      # assume it is a schema file and return it:
      return ($schema->[0],$schema->[1],$schema->[2]);
    }
  }
  return;
}

=head2 resolve_data_path

Get absolute path to the file

=cut

sub resolve_data_path {
  my ($self, $f, $base_data_dir) = @_;
  my ($schema_name,$data_dir,$new_filename) = $self->locate_file($f);
  my $path;
  if (defined($schema_name) and defined($data_dir)) {
    $f = $new_filename if defined $new_filename;
    my $data_source = $self->data_sources->single({layer => $schema_name});
    if ($data_source) {
      $data_source = File::Spec->catdir($base_data_dir, $data_source->path)
        unless $data_source eq File::Spec->rel2abs($data_source); # data_source dir is relative, prefix it with configured data dir
      $path = File::Spec->rel2abs($f, $data_source);
      # print STDERR "F: schema '$schema_name', file: $f, located: $path in configured sources\n";
    } else {
      $path = File::Spec->rel2abs($f, $data_dir);
      # print STDERR "F: schema '$schema_name', file: $f, located: $path in data-dir\n";
    }
  } else {
    # print STDERR "did not find $f in the database\n";
    my $uri = URI->new($f);
    unless ($uri->scheme) { # it must be a relative URI
      $uri->scheme('file'); # convert it to file URI
      my $file = $uri->file;
      unless (File::Spec->file_name_is_absolute($file) && -e $file) { # must be a relative path
        ($path) = Treex::PML::FindInResources($file, {strict=>1});
        if (!defined($path) or $path eq $file) {  # must be in resource dir
          (undef,undef,$file)=File::Spec->splitpath($file);
          ($path) = Treex::PML::FindInResources($file, {strict=>1});
          undef $path if $path and $path eq $file; # must be in resource dir
        }
      }
    }
  }
  return $path;
}

sub generate_doc {
  my $self = shift;

  my (@aux, %doc);
  my $ev = $self->get_evaluator;
  SCHEMA:
  for my $layer (@{$ev->get_schema_names}) {
    for my $type (@{$ev->get_node_types($layer)}) {
      my $decl = $ev->get_decl_for($type) || next;
      for my $attr (map { my $t = $_; $t=~s{#content}{content()}g; $t }
                    map $_->[0],
                    sort { $a->[1]<=>$b->[1] or $a->[0] cmp $b->[0] }
                    map [$_,scalar(@aux = m{/}g) ],
                    $decl->get_paths_to_atoms({ no_childnodes => 1 })) {
        my $mdecl = $decl->find($attr,1);
        next unless $mdecl;
        next if $mdecl->get_role();
        $mdecl=$mdecl->get_knit_content_decl unless $mdecl->is_atomic;
        next if ($mdecl->get_decl_type == PML_CDATA_DECL and $mdecl->get_format eq 'PMLREF');

        $doc{layer} = $layer;
        $doc{type} = $type;
        $doc{attr} = $attr;
        $doc{value} = '...some value...';

        my ($sth) =
        $self->run_query(query => qq{$type \$n:=[ $attr=$attr ]>>\$n.$attr}, select_first => 1);
        if (ref($sth) and !$sth->err) {
          my $row = $sth->fetch;
          $doc{value} = $row->[0];
        }
        last SCHEMA;
      }
    }
  }

  return \%doc;
}

1;
