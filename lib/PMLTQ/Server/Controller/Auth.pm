package PMLTQ::Server::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller';

use PMLTQ::Server::Validation;
use List::Util qw(first);
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
  my $c = shift;

  unless ($c->config->{shibboleth}) {
    $c->rendered(404);
    return;
  }

  my $headers = $c->req->headers;
  my $redirect = $c->req->param('loc');

   return $c->status_error({
      code => 400,
      message => 'Redirect location parameter is missing'
    }) unless $redirect;

  if ($headers->header('shib-session-id')) {
    my $organization = $headers->header('shib-identity-provider') || '';

    my $persistent_token = first {defined} map { $headers->header($_) }
      qw(eppn persistent-id mail);

    return $c->redirect_to($redirect . '#no-metadata') unless $persistent_token;

    my $email = first {defined} split(/;/, $headers->header('mail') || '');
    my $first_name = $headers->header('givenName') || '';
    my $last_name = $headers->header('sn') || '';
    my $name = "$first_name $last_name";
    $name =~ s/^\s+|\s+$//g;

    $name = $headers->header('cn') unless $name;

    if ($c->authenticate('', '', {
        email => $email,
        name => $name,
        provider => 'Shibboleth',
        organization => $organization,
        persistent_token => $persistent_token
      })) {
      return $c->redirect_to($redirect . '#success');
    } else {
      # TODO: We should never get here unless server error
      return $c->redirect_to($redirect . '#failed');
    }
  }

  $c->rendered(403);
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
