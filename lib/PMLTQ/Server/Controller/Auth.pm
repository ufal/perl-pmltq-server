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

  my $auth_data = $c->req->json('/auth') || {};
  #print STDERR $c->dumper($c->req->json);
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

# TODO: check Shibboleth attributes to actually create user accounts
sub sign_in_shibboleth {
  my $self = shift;

  my $req = $self->req;

  if ($req->header('shib-session-id')) {
    my $organization = $req->header('shib-identity-provider');

    my $persistent_token = first {defined} map { $req->header($_) }
      qw(eppn persistent-id mail);

    return $self->status_error({
      code => 400,
      message => "Your shibboleth provider does't expose required attributes"
    }) unless $persistent_token;

    if ($self->authenticate('', '', { persistent_token => $persistent_token })) {
      # User exists
      return $self->render(json => $self->current_user->json());
    } else {

    }
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
