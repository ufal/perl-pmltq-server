package PMLTQ::Server;
use Mojo::Base 'Mojolicious';

use Mango;
use Mango::BSON ':bson';
use PMLTQ::Server::Model;

has db => sub { state $mango = Mango->new(shift->config->{mongo_uri}) };

has mandel => sub { state $mandel = PMLTQ::Server::Model->new(storage => shift->db) };

# This method will run once at server start
sub startup {
  my $self = shift;

  $self->plugin('Config' => {
    file => $self->home->rel_file('config/pmltq_server.conf')
  });

	$self->helper(mango => sub { shift->app->db });
  $self->helper(mandel => sub { shift->app->mandel });

  # Show log in STDERR
  $self->log->handle(\*STDERR);

  # Setup all helpers
  $self->setup_helpers();

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('Auth#login');

  my $treebank = $r->bridge('/:treebank')->
    name('treebank')->to(controller => 'Treebank', action => 'initialize');
  $treebank->get ('metadata')->to('#metadata');
  $treebank->post('suggest')->to('#suggest');
  $treebank->get ('history')->to(controller => 'History', action => 'list');
  $treebank->post('query')->to(controller => 'Query', action => 'query');
  $treebank->post('query/svg', 'query_svg')->to(controller => 'Query', action => 'query_svg');
  $treebank->post('svg')->to(controller => 'Query', action => 'result_svg');

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
  my $self = shift;
  $self->helper(status_error => \&_status_error);
}

sub _status_error {
  my ($self, @errors) = @_;

  die __PACKAGE__, 'No errors to render' unless @errors;

  if (@errors == 1) {
    my $error = shift @errors;
    $self->res->code($error->{code});
    $self->render(json => { error => $error->{message} });
  } else {
    # find lowest code and display only those errors
    my $code = min map { $_->{code} } @errors;

    @errors = grep { $_->{code} == $code } @errors;
    return $self->status_error(@errors) if @errors == 1;

    $self->res->code($code);
    $self->render(json => {
      message => 'The request cannot be fulfilled because of multiple errors',
      errors => [ map { $_->{message} } @errors ]
    });
  }
}

1;
