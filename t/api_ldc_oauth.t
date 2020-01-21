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
my %test_treebanks = map {$_ => test_treebank({name => $_, title => $_, is_public => 1, is_free => 0, is_all_logged => 0}) } qw/a b c d/;
$test_treebanks{free} = test_treebank({name => 'free', title => 'free', is_public => 1, is_free => 1, is_all_logged => 1});
my %available_treebanks = {};
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
  print STDERR "test whether is user removed from database !!!\n";
}

sub set_treebanks_for_user {
  my $tb_list = shift // [];
  %available_treebanks = map {$_ => 1} @$tb_list;
  my $req = HTTP::Request->new('POST' => "$oauth_server_url/config_server", undef, Mojo::JSON::encode_json({treebanks => $tb_list}));
  my $ua = LWP::UserAgent->new();
  my $res = $ua->request($req);
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
print STDERR $redirect_url,"\n";


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







done_testing();
