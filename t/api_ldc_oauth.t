use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::JSON;
use File::Basename 'dirname';
use File::Spec;
use List::Util 'any';

use lib dirname(__FILE__);

require 'bootstrap.pl';

start_postgres();
my $t = test_app();

my $oauth = {
      client_id => 'test_client_id',
      app_secret_path => 't/test_files/test_secret_file',
      login_url => 'https://login_url/code',
      token_url => 'https://token_url/token',
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
my $config_client_id = $t->app->config->{oauth}->{ldc}->{client_id};

my $redirect_url = $ldc_url_code;
$redirect_url =~ s{/v[0-9]+}{/api};
$redirect_url =~ s{/}{\%2F}g;
print STDERR $redirect_url,"\n";

$t->get_ok($ldc_url)
  ->status_is(302)
  ->header_like("location"=> qr/$config_login_url/, "location is set")
  ->header_like("location"=> qr/client_id=$config_client_id/, "client id")
  ->header_like("location"=> qr/redirect_uri=.*$redirect_url/, "redirect url")
  ->header_like("location"=> qr/state=[0-9a-f]+/, "state is in path")
  ->header_like("location"=> qr/response_type=code/, "response_type");

my ($state) =  $t->tx->res->headers->location =~ m/state=([0-9a-f]+)/;
my ($state_cookie) = grep {$_->name eq 'state'} @{$t->tx->res->cookies};
if(ok $state_cookie, "cookie state is set") {
  like $state_cookie->value, qr/$state/, "state is in cookie";
}





done_testing();
