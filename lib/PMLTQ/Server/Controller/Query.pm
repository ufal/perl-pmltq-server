package PMLTQ::Server::Controller::Query;

# ABSTRACT: Handling everything related to query execution

use Mojo::Base 'Mojolicious::Controller';
use PMLTQ::Server::Validation;
use Encode qw(encode_utf8);

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

=item C<names> (array[array[string]]|optional)

Array of pairs of node name (as named in the query) and node type. Present
only in case of running query without the filters.

=item C<results> (array[array[string]]|required)

List of node handles or a table in case of running with filters.

=back

B<Example:>

    {
      nodes: [['a', 'a-node'], ['', 't-node']],
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
      $tb->run_query(
        %$input,
        use_cursor => 1,
        debug_sql => (($input->{query} =~ /^#\s*DEBUG=1\s/) ? 1 : 0)
      );
  };

  my $err = $@;
  if ($err) {
    $tb->close_evaluator();
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

  unless($sth){
    $tb->close_evaluator();
    return;
  }
  my $user = $self->current_user;
  $user->touch() if $user;

  if($user && $user->allow_history && ! $input->{nohistory}) {
    my $history = $user->history();
    my $todelete_records_cnt = $self->db->resultset('QueryRecord')->count({query_file_id => $history->id}) - $self->history_limit + 1;
    if($todelete_records_cnt > 0) {
      my $rec = $self->db->resultset('QueryRecord')->search_rs({query_file_id => $history->id},{order_by => 'created_at', rows => $todelete_records_cnt });
      $self->app->log->debug('[HISTORY LIMIT REACHED]: DELETING '.$todelete_records_cnt.' RECORDS');
      $rec->delete_all();
    }
    my $time = time();
    my $collapsed = collapse_query()->($input->{query});
    my $query_record = $self->db->resultset('QueryRecord')->create({
      name => $time,
      user_id => $user->id,
      query => $input->{query},
      query_file_id => $history->id,
      #first_used_treebank => $tb->id,
      ord => $time,
      hash => encode_utf8($collapsed),
    });
    $self->db->resultset('QueryRecordTreebank')->create({
      query_record_id => $query_record->id,
      treebank_id => => $tb->id
    });
    if($input->{query_record_id} && $self->db->resultset('QueryRecord')->find($input->{query_record_id}) ){
      $self->app->log->debug('[QUERY RECORD]: '.$input->{query_record_id});
      $self->app->log->debug($self->db->resultset('QueryRecord')->find($input->{query_record_id}));
      $self->db->resultset('QueryRecordTreebank')->find_or_create({
        query_record_id => $input->{query_record_id},
        treebank_id => => $tb->id
      });
    }
    $self->app->log->debug('[USER]: '.$user->id.'  '.$user->name);
    $self->app->log->debug('[COLLAPSED]: '.$collapsed);

  }

  $self->app->log->debug('[BEGIN_PMLTQ]');
  $self->app->log->debug($input->{query});
  $self->app->log->debug('[END_PMLTQ]');

  $self->app->log->debug('[BEGIN_SQL]');
  $self->app->log->debug($evaluator->get_sql);
  $self->app->log->debug('[END_SQL]');

  my $treebank_nodes = { map { $_ => 1 } @{$tb->get_evaluator()->get_node_types()} };
  eval {
    my @nodes = map { [$_->{name} || '', $_->{'node-type'}] }
                grep { exists $treebank_nodes->{$_->{'node-type'}} } @$query_nodes;
    my @results;
    while (my $row = $evaluator->cursor_next()) {
      push @results, $row;
    }

    $tb->close_evaluator();

    return $self->status_error({
      code => 500,
      message => "Database error while saving history: $err"
    }) if $err;

    $self->render(json => {
      ( $returns_nodes ? (nodes => [@nodes]) : () ),
      results => [@results]
    });
  };

  $err = $@;
  if ($err) {
    $self->status_error({
      code => 500,
      message => "INTERNAL SERVER ERROR: $err"
    })
  }
  $tb->close_evaluator();
}

1;
