package PMLTQ::Server::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller';

use PMLTQ::Server::Validation;
use List::Util qw(first);
use Mojo::JSON;
use Encode qw(decode_utf8);

use Crypt::Digest::SHA512;
use Crypt::JWT;
use HTTP::Request;

sub render_user {
  my $c = shift;

  $c->render(json => { user => $c->is_user_authenticated ? $c->current_user : Mojo::JSON->false,
             login_with => $c->config->{login_with} // {local => 1} });
}

sub check {
  my $c = shift;
  $c->basic_auth({
    invalid => sub {
      any => sub {
        my $ctrl = shift;
        $ctrl->res->headers->remove('WWW-Authenticate');
        $ctrl->res->code(200);
        $ctrl->render_user;
      }
    }
  }) and $c->render_user;
}

sub is_admin {
  my $c = shift;

  unless ($c->is_user_authenticated) {
    $c->status_error({
      code => 401,
      message => 'Authentication required'
    });

    return;
  }

  if ($c->current_user && !$c->current_user->is_admin) {
    $c->status_error({
      code => 403,
      message => 'Access denied'
    });

    return;
  }

  return 1;
}

sub sign_in {
  my $c = shift;

  unless ($c->config->{login_with}->{local}) {
    $c->rendered(404);
    return;
  }

  my $auth_data = $c->req->json('/auth') || {};
  #print STDERR $c->dumper($c->req->json);
  if(($auth_data = $c->_validate_auth($auth_data))
    && $c->authenticate($auth_data->{username}, $auth_data->{password})) {
    $c->render_user;
  } else {
    $c->app->log->debug('Invalid credentials');
    $c->status_error({
      code => 400,
      message => 'Invalid username or password'
    });
  }
}

sub sign_in_ldc {
  my $c = shift;

  unless ($c->config->{login_with}->{ldc}) {
    $c->rendered(404);
    return;
  }
  my $state_code = sprintf "%06x", rand(0xffffff);

  $c->signed_cookie("state_$state_code" => $c->req->param('loc'));

  my $url = $c->url_for($c->config->{oauth}->{ldc}->{login_url});
  my $redir_url = $c->app->url_for('auth_ldc_code')->to_abs;
  # $redir_url =~ s{^/v\d+/}{/api/};
  $c->redirect_to(
    $url->query(
      client_id => $c->config->{oauth}->{ldc}->{client_id},
      response_type => 'code',
      state => $state_code,
      redirect_uri =>  $c->req->url->base->scheme . '://' .$c->req->url->to_abs->host_port . $redir_url
    )
    );
}

sub ldc_code {
  my $c = shift;


  unless ($c->config->{login_with}->{ldc}) {
    $c->rendered(404);
    return;
  }
  my $code = $c->req->param('code');
  my $state_code = $c->req->param('state');

  return $c->status_error({
      code => 400,
      message => 'Parameter is missing'
    }) unless ($code and $state_code);

  ## check state code
  my $redirect = $c->signed_cookie("state_$state_code");
  return $c->status_error({
      code => 401,
      message => 'State is not valid'
    }) unless ($redirect);

  ## calculate client_secret
  my $sha = Crypt::Digest::SHA512->new;
  $sha->add($code);
  $sha->addfile($c->config->{oauth}->{ldc}->{app_secret_path});
  my $client_secret = $sha->hexdigest();
  ## get token from .../token

  my %params = (
    client_id => $c->config->{oauth}->{ldc}->{client_id},
    grant_type => 'authorization_code',
    code => $code,
    client_secret => $client_secret
  );
  my $token_url = $c->config->{oauth}->{ldc}->{token_url} .'?'.join('&', map {"$_=$params{$_}"} keys %params);
  my $req = HTTP::Request->new('POST' => $token_url);
  my $ua = LWP::UserAgent->new();
  my $res = $ua->request($req);

  unless($res->is_success) {
    return $c->status_error({
      code => 500,
      message => 'Unexpected OAuth server error: '. $res->decoded_content
    })
  }

  open my $fh, "<", $c->config->{oauth}->{ldc}->{app_secret_path}  or die "could not open file: $!";
  my $key=<$fh>;
  close($fh);

  my $jwt;
  eval {
   $jwt = Crypt::JWT::decode_jwt(token=>$res->decoded_content, alg=>'HS256', key=>$key);
   1;
  } or do {
    return $c->redirect_to($redirect . '#failed');
  };
  my $persistent_token = $jwt->{refresh_token};
  my $expiration = $jwt->{'exp'};
  $expiration = DateTime->from_epoch( epoch => $expiration );
  my %treebank_names = map {lc($_) => 1} @{$jwt->{corpora}};
  my @available_treebanks = grep {exists $treebank_names{$_->name}} $c->all_treebanks()->all;

  if ($c->authenticate('', '', {
      access_all => 0,
      %{$c->default_user_settings('ldc')},
      email => '',
      name => substr(Crypt::Digest::SHA512::sha512_b64u(rand().$$.time),-16) ,
      provider => 'LDC',
      organization => '',
      persistent_token => $persistent_token,
      valid_until => $expiration
    })) {

    $c->current_user->set_available_treebanks([@available_treebanks]);
    $c->signed_cookie(ldc => $persistent_token);
    return $c->redirect_to($redirect . '#success');
  } else {
    # TODO: We should never get here unless server error
    return $c->redirect_to($redirect . '#failed');
  }
 $c->renderer(403);
}



# TODO: check Shibboleth attributes to actually create user accounts
sub sign_in_shibboleth {
  my $c = shift;

  unless ($c->config->{shibboleth}) {
    $c->rendered(404);
    return;
  }

  unless ($c->config->{login_with}->{shibboleth}) {
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
    my $first_name = decode_utf8($headers->header('givenName') || '');
    my $last_name = decode_utf8($headers->header('sn') || '');
    my $name = "$first_name $last_name";
    $name =~ s/^\s+|\s+$//g;

    $name = decode_utf8($headers->header('cn') || '') unless $name;

    if ($c->authenticate('', '', {
        access_all => 1,
        %{$c->default_user_settings('shibboleth')},
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
  my $user_id = $c->logout();
  if(my $user = $c->db->resultset('User')->search_rs({id => $user_id, provider => 'LDC'})->single) {
    $user->delete();
  }
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
