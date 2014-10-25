package PMLTQ::Server::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller';

use PMLTQ::Server::Validation;
use Mojo::JSON;

sub check {
  my $c = shift;

  $c->render(json => { user => $c->is_user_authenticated ? $c->current_user : Mojo::JSON->false });
}

sub sign_in {
  my $c = shift;

  my $auth_data = $c->req->json('/auth');
  print STDERR $c->dumper($c->req->json);
  if(($auth_data = $c->_validate_auth($auth_data))
    && $c->authenticate($auth_data->{username}, $auth_data->{password})) {
    $c->render( json => { user => $c->current_user } )
  } else {
    $c->app->log->debug('Invalid credentials');
    $c->status_error({
      code => 400,
      message => 'Invalid username or password'
    });
  }
}

sub sign_out {
  my $c = shift;
  $c->logout();
  $c->rendered;
}

sub _validate_auth {
  my ($c, $auth_data) = @_;

  my $rules = {
    fields => [qw/username password/],
    filters => [
      username => filter(qw/trim strip/),
    ],
    checks => [
      [qw/username password/] => is_required(),
    ]
  };

  $c->do_validation($rules, $auth_data);
}

1;
