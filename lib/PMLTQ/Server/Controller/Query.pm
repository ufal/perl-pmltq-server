package PMLTQ::Server::Controller::Query;

# ABSTRACT: Handling everything related to query execution

use Mojo::Base 'Mojolicious::Controller';

use Treex::PML::Document;
use Treex::PML::Factory;
use PMLTQ::Common;
use File::Temp;

=head1 METHODS

=head2 query

Run a query on chosen L<PMLTQ::Server::Model::Treebank>

=head3 POST /:treebank_id/query

=over 4

=item C<treebank_id> (string)

Id of the treebank

=back

=head3 Request

=over 4

=item C<query> (string|required)

String query in the PML-TQ syntax.

B<Example:>

    a-node $a := [
      sibling a-node [
        depth-first-follows $a,
        afun=$a.afun,
      ]
    ]

=item C<limit> (integer|optional|default:100|minimum:1)

Maximum number of results to return for node or filter queries.

=item C<filter> (boolean|optional|default:true)

Run with or without output filters.

=item C<timeout> (integer|optional|default:30|maximum:300|minimum:0)

Timeout for query in seconds.

=back

=head3 Response

For queries returning nodes (C<filter = false>) the output contains for each
match a tuple of so called node handles of the matching nodes is returned. The
tuple is ordered in the depth-first order of nesting of node selectors in the
query. The handles can be passed to methods such as /:treebank/node and
/:treebank/svg.

For queries with filter the output can be interpreted as simple table of
results (i.e. array or arrays).

[Node handles: For ordinary nodes, the handle has the form X/T or X/T@I where
X is an integer (internal database index of the corresponding record), T is
the name of the PML type of the node and the optional I value is the PML ID of
the matched node (if available). For member objects (matching the member
relation) the handle has the form X//T.]

=over 4

=item C<names> (array[string]|optional)

Array of node names as named in the query. Present only in case of running
query without the filters.

=item C<results> (array[array[string]]|required)

List of node handles or a table in case of running with filters.

=back

B<Example:>

    {
      names: ['a', ''],
      results: [
        ["10/a-node@a-ln94210-2-p2s1w4","13/a-node@a-ln94210-2-p2s1w7"],
        ["16/a-node@a-ln94210-2-p2s1w9","17/a-node@a-ln94210-2-p2s1w10"]
      ]
    }

=cut

sub query {
  my $self = shift;

  my $input = $self->req->json;

  unless ($input->{query}) {
    $self->status_error({
      code => 400,
      message => 'Query cannot be empty!'
    });
    return;
  }

  # TODO: input validation
  #return unless $self->validate_input($query_payload, $input);

  my $tb = $self->stash('tb');
  my ($sth, $returns_nodes, $query_nodes, $evaluator);
  eval {
    ($sth, $returns_nodes, $query_nodes, $evaluator) =
      $tb->search(
        %$input,
        use_cursor => 1,
        debug_sql => (($input->{query} =~ /^#\s*DEBUG=1\s/) ? 1 : 0)
      );
  };

  my $err = $@;
  if ($err) {
    if ($err =~ /\tTIMEOUT\t/) {
      $self->status_error({
        code => 408,
        message => 'Evaluation of query exceeded specified maximum time limit of '.$input->{timeout}.' seconds'
      });
      return;
    }
    $err =~ s{\bat \S+ line \d+.*}{}s;
    $self->status_error({
      code => 400,
      message => "$err"
    });
    return;
  }

  return unless $sth;

  $self->app->log->debug('[BEGIN_SQL]');
  $self->app->log->debug($evaluator->get_sql);
  $self->app->log->debug('[END_SQL]');

  eval {
    my @names = map { $_->{name} || '' } @$query_nodes;
    my @results;
    while (my $row = $evaluator->cursor_next()) {
      push @results, $row;
    }

    $tb->record_history($self->history_key, $input->{query}, $self->current_user, sub {
      my($rec, $err) = @_;

      return $self->status_error({
        code => 500,
        message => "Database error while saving history: $err"
      }) if $err;

      $self->render(json => {
        ( $returns_nodes ? (names => [@names]) : () ),
        results => [@results]
      })
    });

    $self->render_later;
    return;
  };

  $err = $@;
  if ($err) {
    $self->status_error({
      code => 500,
      message => "INTERNAL SERVER ERROR: $err"
    })
  }
}

=head2 query_svg

Returns an SVG document with the mime-type C<image/svg+xml> rendering a
graphical representation of the input PML-TQ query.

NOTE: This requires to have correctly configured url C<tree_print_service>
pointing at the working print server as the rendering is done by the server.

=head3 POST /:treebank_id/query/svg

=over 4

=item C<treebank_id> (string)

Id of the treebank

=back

=head3 Request

=over 4

=item C<query> (string|required)

String query in the PML-TQ syntax.

B<Example:>

    a-node $a := [
      sibling a-node [
        depth-first-follows $a,
        afun=$a.afun,
      ]
    ]

=back

=head3 Response

A rendered SVG document

B<Example:>

    <svg xmlns="http://www.w3.org/2000/svg" version="1.1">
      <title>sample0.a.gz (2/54)</title>
      <desc>....</desc>
      <g transform="translate(5 5)">
        <path ..... ></path>
      </g>
    </svg>

=cut

sub query_svg {
  my $self = shift;

  unless ($self->config->{tree_print_service}) {
    $self->status_error({
      code => 500,
      message => "Print service not available or not defined"
    });
    return
  }

  my $input = $self->req->json;
  # TODO: input validation
  # return unless $self->validate_input($query_svg_payload, $input);
  my $tb = $self->stash('tb');

  my $evaluator;
  my $tree;
  eval {
    $evaluator = $tb->get_evaluator;
    $tree = PMLTQ::Common::parse_query($input->{query},{
      pmlrf_relations => $evaluator->get_pmlrf_relations,
      user_defined_relations => $evaluator->get_user_defined_relations,
    });
    Treex::PML::Document->determine_node_type($_) for ($tree->descendants);
    PMLTQ::Common::CompleteMissingNodeTypes($evaluator,$tree);
  };

  my $err = $@;
  if ($err) {
    $err =~ s{\bat \S+ line \d+.*}{}s;
    $self->status_error({
      code => 500,
      message => "$err"
    });
    return
  }

  my $fh = File::Temp->new(
    UNLINK=>0,
    SUFFIX=>'.query.pml',
    DIR => $self->config->{tmp_dir}
  );
  my $path = $fh->filename;
  my $pml = PMLTQ::Common::NewQueryFileInstance($path);
  $pml->{'_trees'} = Treex::PML::Factory->createList;
  $pml->get_trees->append($tree);
  $pml->save({ fh => $fh, filename => $path });
  $fh->flush;
  #print STDERR $path;

  $self->app->ua->post(
    $self->config->{tree_print_service} => form => {
      file => $path,
      tree_no => 1,
      sentence => 0,
      fileinfo => 0,
      dt => 0,
      no_cache => 1
    } => sub {
      my ($ua, $tx) = @_;
      if (my $res = $tx->success) {
        $res->headers->content_type('image/svg+xml');
        $self->tx->res($res);
        $self->rendered($res->code);
      } else {
        my ($err, $code) = $tx->error;
        $self->app->log->debug($err->{message});
        $self->status_error({
          code => $code||500,
          message => $err->{message}
        })
      }
    });

  $self->render_later;
}

=head2 result_svg

Returns an SVG document with the mime-type C<image/svg+xml> rendering a tree.

=head3 POST /:treebank_id/svg

=over 4

=item C<treebank_id> (string)

Id of the treebank

=back

=head3 Request

=over 4

=item C<nodes> (array[string]|required)

Array of node ids or handles. Currently, if C<nodes> contains a list of node
handles, only the first handle in the list is used.

=item C<tree> (integer)

If C<tree> is less or equal 0 or not specified, the rendered tree is the tree
containing the node corresponding to the given node handle.

If C<tree> is a positive integer N, the returned SVG is a rendering of Nth
tree in the document containing the node corresponding to the given node handle.

=back

=head3 Response

A rendered SVG document

B<Example:>

    <svg xmlns="http://www.w3.org/2000/svg" version="1.1">
      <title>sample0.a.gz (2/54)</title>
      <desc>....</desc>
      <g transform="translate(5 5)">
        <path ..... ></path>
      </g>
    </svg>

=cut

sub result_svg {
  my $self = shift;

  unless ($self->config->{tree_print_service}) {
    $self->status_error({
      code => 500,
      message => "Print service not available or not defined"
    });
    return
  }

  my $input = $self->req->json;
  # TODO: input validation
  # return unless $self->validate_input($result_svg_payload, $input);
  my $tb = $self->stash('tb');

  my $path;
  eval {
    my ($f) = $tb->get_evaluator
      ->idx_to_pos([$input->{nodes}->[0]]);
    #print STDERR "$f\n";
    if ($f) {
      $input->{tree}=$1 if ($f=~s{##(\d+)(?:\.\d+)?}{} and !$input->{tree});
      $path = $tb->resolve_data_path($f, $self->config->{data_dir});
      $self->app->log->debug("File path: $path");
    }
  };
  my $err = $@;
  if ($err) {
    $err =~ s{\bat \S+ line \d+.*}{}s;
    $self->status_error({
      code => 500,
      message => "INTERNAL SERVER ERROR: $err"
    });
    $self->app->log->debug("INTERNAL SERVER ERROR: $err");
    return
  }

  unless (defined $path) {
    $self->status_error({
      code => 404,
      message => "File not found"
    });
    return
  }

  $self->app->ua->post(
    $self->config->{tree_print_service} => form => {
      file => $path,
      tree_no => $input->{tree},
      sentence => 1,
      fileinfo => 1,
      dt => 1
    } => sub {
      my ($ua, $tx) = @_;
      if (my $res = $tx->success) {
        $res->headers->content_type('image/svg+xml');
        $self->tx->res($res);
        $self->rendered($res->code);
      } else {
        my ($err, $code) = $tx->error;
        $self->app->log->debug($err->{message});
        $self->status_error({
          code => $code||500,
          message => $err->{message}
        })
      }
    });

  $self->render_later;
}
1;
