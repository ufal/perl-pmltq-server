package PMLTQ::Server::Model::Treebank;

# ABSTRACT: Model representing a treebank

use PMLTQ::Server::Document 'treebanks';

use Types::Standard qw(Str ArrayRef HashRef);

use Digest::SHA qw(sha1_hex);
use PMLTQ::SQLEvaluator;
use Treex::PML;
use File::Spec;
use URI;

=head1 ATTRIBUTES

=cut

field [qw/name title driver host port database username password/] => ( isa => Str );

field data_sources => ( isa => ArrayRef[HashRef[Str]] );

has_many histories => 'PMLTQ::Server::Model::History';

=head1 METHODS

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
  my $key = $self->name;

  unless ($evaluators->{$key}) {
    my $evaluator = PMLTQ::SQLEvaluator->new(undef, {
      connect => {
        driver => $self->driver,
        host => $self->host,
        port => $self->port,
        database => $self->database,
        username => $self->username,
        password => $self->password
      }
    });
    $evaluator->connect();
    $evaluators->{$key} = $evaluator;
  }

  return $evaluators->{$key};
}

=head2 record_history

Saves a query to the history for the current user.

  $tb->record_history($query, $current_user, $callback);

=cut

sub record_history {
  my ($self, $query, $user, $cb) = @_;

  return unless $query and $user;

  my $rec = $self->connection->collection('history')->create({
    query => $query,
  });
  $rec->user($user->id);
  $rec->treebank($self->id);

  if ($cb) {
    $rec->save($cb)
  } else {
    $rec->save;
    return $rec;
  }
}

=head2 search

Will do a actual search on the treebank using the L<PMLTQ::SQLEvaluator>.

=cut

sub search {
  my $self = shift;
  my %opts = (limit => 100, @_);

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
      #print STDERR "testing: $what $n $f\n";
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
  my ($self, $f) = @_;
  my ($schema_name,$data_dir,$new_filename) = $self->locate_file($f);
  my $path;
  if (defined($schema_name) and defined($data_dir)) {
    $f = $new_filename if defined $new_filename;
    my ($sources) = map $_->{path}, grep { $_->{schema} eq $schema_name } @{$self->data_sources};

    if ($sources) {
      $path = URI::file->new($f)->abs(URI::file->new($sources.'/'))->file;
      #print STDERR "F: schema '$schema_name', file: $f, located: $path in configured sources\n";
    } else {
      $path = URI::file->new($f)->abs(URI::file->new($data_dir.'/'))->file;
      #print STDERR "F: schema '$schema_name', file: $f, located: $path in data-dir\n";
    }
  } else {
    #print STDERR "did not find $f in the database\n";
    my $uri = URI->new($f);
    if (!$uri->scheme) { # it must be a relative URI
      $uri->scheme('file'); # convert it to file URI
      my $file = $uri->file;
      unless (File::Spec->file_name_is_absolute($file)) { # must be a relative path
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
