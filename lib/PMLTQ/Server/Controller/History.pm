package PMLTQ::Server::Controller::History;

use Mojo::Base 'Mojolicious::Controller';

sub list {
  my $c = shift;

  my $history = $c->mandel->collection('history');

  my $user = $c->current_user;
  if ($user) {
    $history = $history->search({'user.$id' => $user->id});
  } else {
    my $history_key = $c->history_key;
    $history = $history->search({history_key => $history_key});
  }

  my $treebank = $c->stash('tb');
  $history = $history->search({'treebank.$id' => $treebank->id}) if $treebank;

  $history->all(sub {
    my($self, $err, $records) = @_;
    if ($err) {
      return $c->status_error({
        code => 500,
        message => $err
      });
    }

    $c->render(json => $records);
  });

  $c->render_later;
}

1;
