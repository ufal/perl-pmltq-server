package PMLTQ::Server::Controller::History;

use Mojo::Base 'Mojolicious::Controller';


sub initialize {
  my $c = shift;

  unless ($c->is_user_authenticated) {
    $c->status_error({
      code => 401,
      message => 'Authentication required'
    });

    return;
  }

  my $history = $c->db->resultset('QueryFile')->search_rs(user_id => $c->current_user->id);

  return 1;
}

sub list {
  my $c = shift;

  my $user = $c->current_user;

  $c->render(json => []);

  # my $history = $c->mandel->collection('history');

  # my $user = $c->current_user;
  # if ($user) {
  #   $history = $history->search({'user.$id' => $user->id});
  # } else {
  #   my $history_key = $c->history_key;
  #   $history = $history->search({history_key => $history_key});
  # }

  # my $treebank = $c->stash('tb');
  # $history = $history->search({'treebank.$id' => $treebank->id}) if $treebank;

  # $history->all(sub {
  #   my($self, $err, $records) = @_;
  #   if ($err) {
  #     return $c->status_error({
  #       code => 500,
  #       message => $err
  #     });
  #   }

  #   $c->render(json => $records);
  # });

  # $c->render_later;
}

1;
