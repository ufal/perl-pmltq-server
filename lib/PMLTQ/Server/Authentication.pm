package PMLTQ::Server::Authentication;

use Mojo::Base 'Mojolicious::Plugin';
use PMLTQ::Server::Validation 'check_password';

sub register {
  my ($self, $app) = @_;

  $app->plugin(Authentication => {
    autoload_user => 0,
    session_key   => 'auth_data',
    our_stash_key => 'auth',
    load_user     => sub { $self->load_user(@_) },
    validate_user => sub { $self->validate_user(@_) }
  });
}

sub load_user {
  my ($self, $c, $user_id) = @_;
  my $user = $c->db->resultset('User')->find($user_id);
  $c->app->log->debug('Failed to load user.') unless $user;
  # TODO test if not expired
  if($user and $user->provider//'' eq 'LDC'){
    if(defined($user->valid_until) && $user->valid_until < DateTime->now()) {
      $self->refresh_session($c,$user);
    }
  }
  $user->touch();
  return $user;
}

sub validate_user {
  my ($self, $c, $username, $password, $user_data) = @_;

  if ($user_data && $user_data->{persistent_token}) {
    return $self->register_or_load($c, { map { ($_ => $user_data->{$_}) } qw/persistent_token organization provider/ }, $user_data);
  }
  my $user = $c->db->resultset('User')->single({ username => $username });
  my $user_id = $user && $user->check_password($password) ? $user->id : undef;
  $c->app->log->debug("Authentication failed for: ${username}") unless $user_id;
  return defined $user_id ? "$user_id" : undef;
}

sub register_or_load {
  my ($self, $c, $search, $data) = @_;

  my $users_rs = $c->db->resultset('User');
  my $user = $users_rs->single($search);

  unless ($user) {
    $user = $users_rs->new_result({
      is_active => 1,
      %$data,
      is_admin => 0
    });
    $user->insert();
  }

  return $user->id;
}

sub refresh_session {
  my ($self, $c, $user) = @_;

  ## calculate client_secret
  my $sha = Crypt::Digest::SHA512->new;
  $sha->add($user->persistent_token);
  $sha->addfile($c->config->{oauth}->{ldc}->{app_secret_path});
  my $client_secret = $sha->hexdigest();
  ## get token from .../token

  my %params = (
    client_id => $c->config->{oauth}->{ldc}->{client_id},
    grant_type => 'refresh_token',
    refresh_token => $user->persistent_token,
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

  my $jwt = Crypt::JWT::decode_jwt(token=>$res->decoded_content, alg=>'HS256', key=>$key);
  my $persistent_token = $jwt->{refresh_token};
  my $expiration = $jwt->{'exp'};
  $expiration = DateTime->from_epoch( epoch => $expiration );
  my %treebank_names = map {$_ => 1} @{$jwt->{corpora}};
  my @available_treebanks = grep {exists $treebank_names{$_->name}} $c->all_treebanks()->all;

  $user->persistent_token($persistent_token);
  $user->valid_until($expiration);

  my $users_rs = $c->db->resultset('User');
  $users_rs->recursive_update({id => $user->id, persistent_token => $persistent_token, valid_until => $expiration});

  $user->set_available_treebanks([@available_treebanks]);
  $c->signed_cookie(ldc => $persistent_token);
}

1;
