package PMLTQ::Server::Controller::Treebank;

# ABSTRACT: Handling everything related to treebanks

use Mojo::Base 'Mojolicious::Controller';

use PMLTQ::Server::Model::Treebank;

=head1 METHODS

=head2 initialize

Bridge for other routes. Saves current treebank to stash under 'tb' key.

=cut

sub initialize {
  my $c = shift;

  my $tb_name = $self->param('treebank');
  $c->mango->db->collection('treebanks')->find_one({name => $tb_name} => sub {
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

    $c->stash(tb => PMLTQ::Server::Model::Treebank->new($tb));
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
