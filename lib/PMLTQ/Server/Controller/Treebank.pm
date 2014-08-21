package PMLTQ::Server::Controller::Treebank;

# ABSTRACT: Handling everything related to treebanks

use Mojo::Base 'Mojolicious::Controller';

=head1 METHODS

=head2 initialize

Bridge for other routes. Saves current treebank to stash under 'tb' key.

=cut

sub initialize {
  my $c = shift;

  my $tb_name = $c->param('treebank');
  $c->mandel->collection('treebank')->search({name => $tb_name})->single(sub {
    my ($collection, $err, $tb) = @_;

    unless ($tb) {
      $c->status_error({
        code => 404,
        message => "Treebank '$tb_name' not found"
      });
      return;
    }

    if ($err) {
      $c->status_error({
        code => 500,
        message => "Database error: $err"
      });
      return;
    }

    $c->stash(tb => $tb);
    $c->continue;
  });

  return undef;
}

sub metadata {}

sub suggest {}

# crud

sub list {}
sub create {}
sub fetch {}
sub remove {}
sub update {}

1;
