package PMLTQ::Server;
use Mojo::Base 'Mojolicious';

use Mango;
use Mango::BSON ':bson';

has db => sub { state $mango = Mango->new(shift->config->{mongo_uri}) };

# This method will run once at server start
sub startup {
  my $self = shift;

  $self->plugin('Config' => {
    file => $self->home->rel_file('config/pmltq_server.conf')
  });

	$self->helper(mango => sub { shift->app->db });

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('Auth#login');

  $r->get('/mongotest' => sub {
    my $c = shift;

    my $collection = $c->mango->db->collection('visitors');
    my $ip         = $c->tx->remote_address;

    # Store information about current visitor
    $collection->insert({when => bson_time, from => $ip} => sub {
      my ($collection, $err, $oid) = @_;

      return $c->render_exception($err) if $err;

      # Retrieve information about previous visitors
      $collection->find->sort({when => -1})->fields({_id => 0})->all(sub {
        my ($collection, $err, $docs) = @_;

        return $c->render_exception($err) if $err;

        # And show it to current visitor
        $c->render(json => $docs);
      });
    });

    $c->render_later;
  })
}


sub setup_helpers {

}

1;
