use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::JSON;
use File::Basename 'dirname';
use File::Spec;
use List::Util 'any';
use URL::Encode;

use lib dirname(__FILE__);

require 'bootstrap.pl';

start_postgres();
my $t = test_app();
my %test_treebanks = map {$_ => test_treebank({name => $_, title => $_, is_public => 1, is_free => 0, is_all_logged => 0}, {treebank_provider_ids => {ldc => "ldc_$_"}}) } qw/a b c d/;
$test_treebanks{free} = test_treebank({name => 'free', title => 'free', is_public => 1, is_free => 1, is_all_logged => 1});
my %available_treebanks = ();
my $code = '0123456789abcdef';
my $config_client_id = 'test_client_id';
my $state_url = 'CURRENT_STATE_URL';
my $test_secret_file = File::Spec->catfile(dirname(__FILE__), 'test_files', 'test_secret_file');
my $oauth_server_url = Mojo::URL->new(start_oauth_server($code, $test_secret_file,$config_client_id));

my $oauth = {
      client_id => $config_client_id,
      app_secret_path => $test_secret_file,
      login_url => "$oauth_server_url/code",
      token_url => "$oauth_server_url/token",
  };
$t->app->config->{oauth} = {ldc => $oauth};

sub logout {
  ok $t->app->routes->find('auth_sign_out'), 'Auth sign out route exists';
  my $auth_sign_out_url = $t->app->url_for('auth_sign_out');
  ok ($auth_sign_out_url, 'Has auth sign out url');

  $t->delete_ok($auth_sign_out_url)
    ->status_is(200)
    ->json_is('/' => undef);

  ok $t->app->routes->find('auth_check'), 'Auth check route exists';
  my $auth_check_url = $t->app->url_for('auth_check');
  ok ($auth_check_url, 'Has auth check url');

  $t->get_ok($auth_check_url)
    ->status_is(200)
    ->json_is('/user', Mojo::JSON->false);
}

sub set_treebanks_for_user {
  my $tb_list = shift // [];
  %available_treebanks = map {($_ => 1)} @$tb_list;
  my $req = HTTP::Request->new('POST' => "$oauth_server_url/config_server", undef, Mojo::JSON::encode_json({treebanks => [map {"ldc_$_"} @$tb_list]}));
  my $ua = LWP::UserAgent->new();
  my $res = $ua->request($req);
}

sub force_current_user_token_expiration {
  set_user_expiration(shift,-1);
}

sub set_user_expiration {
  my $user_id = shift;
  my $minutes = shift;
  test_db()->resultset('User')->recursive_update({id => $user_id, valid_until => DateTime->now()->add(minutes => $minutes)});
}

sub test_treebank_accessibility {
  my $message = shift // '';
  subtest "Treebank accessibility: $message" => sub {
    for my $tbname (sort keys %test_treebanks) {
      my $treebank_url = $t->app->url_for('treebank', treebank_id => $test_treebanks{$tbname}->id);
      if($test_treebanks{$tbname}->is_free) {
        $t->get_ok($treebank_url)
          ->status_is(200, "Free treebank is available");
      } elsif (exists $available_treebanks{$tbname}) {
        $t->get_ok($treebank_url)
          ->status_is(200, "Allowed treebank is available");
      } else {
          $t->get_ok($treebank_url)
          ->status_is(403, "Non-free and non-listed is permited");
      }
    }
  }
}

ok $t->app->routes->find('auth_check'), 'Auth check route exists';
my $auth_check_url = $t->app->url_for('auth_check');
ok ($auth_check_url, 'Has auth check url');

$t->get_ok($auth_check_url)
  ->status_is(200)
  ->json_is('/user', Mojo::JSON->false);


ok $t->app->routes->find('auth_ldc'), 'LDC sign in route exists';
my $ldc_url = $t->app->url_for('auth_ldc');
ok ($ldc_url, 'Has LDC sign in url');

ok $t->app->routes->find('auth_ldc_code'), 'LDC sign in code route exists';
my $ldc_url_code = $t->app->url_for('auth_ldc_code');
ok ($ldc_url_code, 'Has LDC sign in code url');

# LDC auth should be disabled by default
$t->get_ok($ldc_url)
  ->status_is(404);

$t->app->config->{login_with}->{ldc} = 1;

my $config_login_url = $t->app->config->{oauth}->{ldc}->{login_url};

my $redirect_url = $ldc_url_code;
#$redirect_url =~ s{/v[0-9]+}{/api};
$redirect_url = URL::Encode::url_encode($redirect_url);;


set_treebanks_for_user([qw/a b d/]);

$t->get_ok("$ldc_url?loc=$state_url")
  ->status_is(302)
  ->header_like("location"=> qr/$config_login_url/, "location is set")
  ->header_like("location"=> qr/client_id=$config_client_id/, "client id")
  ->header_like("location"=> qr/redirect_uri=.*$redirect_url/, "redirect url")
  ->header_like("location"=> qr/state=[0-9a-f]+/, "state is in path")
  ->header_like("location"=> qr/response_type=code/, "response_type");

my ($state) =  $t->tx->res->headers->location =~ m/state=([0-9a-f]+)/;
my ($state_cookie) = grep {$_->name eq "state_$state"} @{$t->tx->res->cookies};
if(ok $state_cookie, "cookie state is set") {
  like $state_cookie->value, qr/$state_url/, "state is in cookie";
}

my ($responsed_redirect_url) = $t->tx->res->headers->location =~ m/redirect_uri=([^&]+)/;
$responsed_redirect_url = URL::Encode::url_decode($responsed_redirect_url);

$t->get_ok("$responsed_redirect_url?code=$code&state=$state")
  ->status_is(302)
  ->header_like("location"=> qr/$state_url/, "redirected to previeous state")
  ->header_like("location"=> qr/success$/, "successfully logged");


test_treebank_accessibility('first login');

$t->get_ok($auth_check_url)
  ->status_is(200);

my $last_user_id = $t->tx->res->json->{user}->{id};
my $persistentToken =  $t->tx->res->json->{user}->{persistentToken};

set_treebanks_for_user([qw/a c/]); # allow different treebanks before expiration

force_current_user_token_expiration($last_user_id);

test_treebank_accessibility('treebank list changed, token expired');
$t->get_ok($auth_check_url)
  ->status_is(200);

ok not($persistentToken eq $t->tx->res->json->{user}->{persistentToken}), "expiration persistentToken";

logout();

subtest "user and all dependencies are removed after logout" => sub {
  is test_db()->resultset('User')->find($last_user_id), undef, "user is not in database";
};


my %new_users;
for my $usrno (-2..2) {
  subtest "loging user [$usrno]" => sub {
    $t->get_ok("$ldc_url?loc=$state_url")
      ->status_is(302);
    ($state) =  $t->tx->res->headers->location =~ m/state=([0-9a-f]+)/;
    ($responsed_redirect_url) = $t->tx->res->headers->location =~ m/redirect_uri=([^&]+)/;
    $responsed_redirect_url = URL::Encode::url_decode($responsed_redirect_url);
    $t->get_ok("$responsed_redirect_url?code=$code&state=$state")
      ->status_is(302)
      ->header_like("location"=> qr/success$/, "successfully logged");

    $t->get_ok($auth_check_url)
      ->status_is(200);
    $last_user_id = $t->tx->res->json->{user}->{id};
    $new_users{"[$usrno]"} = $last_user_id;
    set_user_expiration($last_user_id, $usrno*60 + 5); # add 5 minutes to be sure that correct number of user will be removed
    # do not logout user !!!
  };
}

subtest "test removing user after expiration (validUntil + tolerance)" => sub {
  $t->app->print_user_stats();
  $t->app->remove_expired_users(expiration => 1); # this should remove user [-2]
  ok(! test_db()->resultset('User')->find($new_users{'[-2]'}), "user [-2] removed");
  delete $new_users{'[-2]'};
  ok(test_db()->resultset('User')->find($new_users{$_}), "user $_ exists  ") for sort keys %new_users;

  $t->app->print_user_stats();
  $t->app->remove_expired_users(expiration => -1); # this removes all users that will expires within an hour
  ok(! test_db()->resultset('User')->find($new_users{'[-1]'}), "user [-1] removed");
  ok(! test_db()->resultset('User')->find($new_users{'[0]'}), "user [0] removed");
  delete $new_users{'[-1]'};
  delete $new_users{'[0]'};
  ok(test_db()->resultset('User')->find($new_users{$_}), "user $_ exists  ") for sort keys %new_users;
};

subtest "try to load removed user" => sub {
  $t->get_ok("$ldc_url?loc=$state_url")
    ->status_is(302);
  ($state) =  $t->tx->res->headers->location =~ m/state=([0-9a-f]+)/;
  ($responsed_redirect_url) = $t->tx->res->headers->location =~ m/redirect_uri=([^&]+)/;
  $responsed_redirect_url = URL::Encode::url_decode($responsed_redirect_url);
  $t->get_ok("$responsed_redirect_url?code=$code&state=$state")
    ->status_is(302)
    ->header_like("location"=> qr/success$/, "successfully logged");
  $t->get_ok($auth_check_url)
    ->status_is(200);
  $last_user_id = $t->tx->res->json->{user}->{id};
  set_user_expiration($last_user_id, -5*60); # add 5 minutes to be sure that correct number of user will be removed
  $t->app->remove_expired_users(expiration => 4); # this should remove currently logged user
  ok(! test_db()->resultset('User')->find($last_user_id), "current user removed from database (expiration)");
  $t->get_ok($auth_check_url)
    ->status_is(200)
    ->json_is('/user', Mojo::JSON->false);
};

subtest "try to load expired user but not removed (refresh token)" => sub {
  # Login
  $t->get_ok("$ldc_url?loc=$state_url")
    ->status_is(302);
  ($state) =  $t->tx->res->headers->location =~ m/state=([0-9a-f]+)/;
  ($responsed_redirect_url) = $t->tx->res->headers->location =~ m/redirect_uri=([^&]+)/;
  $responsed_redirect_url = URL::Encode::url_decode($responsed_redirect_url);
  $t->get_ok("$responsed_redirect_url?code=$code&state=$state")
    ->status_is(302)
    ->header_like("location"=> qr/success$/, "successfully logged");
  $t->get_ok($auth_check_url)
    ->status_is(200);
  $last_user_id = $t->tx->res->json->{user}->{id};
  my $last_user_token = $t->tx->res->json->{user}->{persistentToken};
  $t->get_ok($auth_check_url)
    ->status_is(200)
    ->json_is('/user/persistentToken',$last_user_token, 'no token change');
  # expire user and session
  force_current_user_token_expiration($last_user_id);
  ok(test_db()->resultset('User')->find($last_user_id)->valid_until < DateTime->now(), "user is expired");
  ok(test_db()->resultset('User')->find($last_user_id), "user is still in database");
  # Session is alive, token refresh is expected.
  # load refreshed user
  $t->get_ok($auth_check_url)
    ->status_is(200)
    ->json_is('/user/id', $last_user_id)
    ->json_unlike('/user/persistentToken',qr/^$last_user_token$/, 'token changed');
  $t->reset_session();
  # load expired user
  $t->get_ok($auth_check_url)
    ->status_is(200)
    ->json_is('/user', Mojo::JSON->false);
};

subtest "api path is different from site path" => sub {
  $t->app->config->{api_path} = '/api_path/pmltq/api';

  $redirect_url = $ldc_url_code;
  $redirect_url =~ s/^\/v\d+//;
  $redirect_url = URL::Encode::url_encode($t->app->config->{api_path} . $redirect_url);

  $t->get_ok("$ldc_url?loc=$state_url")
    ->status_is(302)
    ->header_like("location"=> qr/$config_login_url/, "location is set")
    ->header_like("location"=> qr/client_id=$config_client_id/, "client id")
    ->header_like("location"=> qr/redirect_uri=.*$redirect_url/, "redirect url")
    ->header_like("location"=> qr/state=[0-9a-f]+/, "state is in path")
    ->header_like("location"=> qr/response_type=code/, "response_type");
  ($state) =  $t->tx->res->headers->location =~ m/state=([0-9a-f]+)/;
  logout();
  undef $t->app->config->{api_path};
};



subtest "oauth server token error" => sub {
  $t->app->config->{oauth} = {ldc => {%$oauth, token_url => "$oauth_server_url/broken_token"}};

  $t->get_ok("$ldc_url?loc=$state_url")
    ->status_is(302);
  ($state) =  $t->tx->res->headers->location =~ m/state=([0-9a-f]+)/;

  $t->get_ok("$responsed_redirect_url?code=$code&state=$state")
    ->status_is(302)
    ->header_like("location"=> qr/$state_url/, "redirected to previeous state")
    ->header_like("location"=> qr/failed$/, "not logged");
  $t->get_ok($auth_check_url)
    ->status_is(200)
    ->json_is('/user', Mojo::JSON->false, 'user is not logged');
};



done_testing();
