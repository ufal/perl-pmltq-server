use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::JSON;
use File::Basename 'dirname';
use File::Spec;
use List::Util 'any';

use lib dirname(__FILE__);

require 'bootstrap.pl';

# Simple test to authenticate default user through api

start_postgres();
my $t = test_app();

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

ok $t->app->routes->find('auth_check'), 'Auth check route exists';
my $auth_check_url = $t->app->url_for('auth_check');
ok ($auth_check_url, 'Has auth check url');

$t->get_ok($auth_check_url)
  ->status_is(200)
  ->json_is('/user', Mojo::JSON->false);

ok $t->app->routes->find('auth_shibboleth'), 'Shibboleth sign in route exists';
my $shibboleth_url = $t->app->url_for('auth_shibboleth');
ok ($shibboleth_url, 'Has shibboleth sign in url');

# Shibboleth auth should be disabled by default
$t->get_ok($shibboleth_url)
  ->status_is(404);

$t->app->config->{shibboleth} = 1;

$t->get_ok($shibboleth_url)
  ->status_is(400)
  ->json_like('/error' => qr/Redirect location parameter is missing/);

my $loc = 'http://happytesting.com/login';
$t->get_ok($shibboleth_url . "?loc=$loc")
  ->status_is(403);

$t->get_ok($shibboleth_url . "?loc=$loc" => {
  'Shib-Session-Id' => '_2690af500207a5891cea6a93eed1fd38'
})->status_is(302)
  ->header_like(Location => qr/$loc#no-metadata/);

$t->get_ok($shibboleth_url . "?loc=$loc" => {
  'Shib-Session-Id' => '_2690af500207a5891cea6a93eed1fd38',
  'Shib-Identity-Provider' => 'https://cas.cuni.cz/idp/shibboleth',
  'Cn' => 'Joe Doe',
  'Mail' => 'mail1@ufal.mff.cuni.cz;mail2@ufal.mff.cuni.cz'
})->status_is(302)
  ->header_like(Location => qr/$loc#success/);

$t->get_ok($auth_check_url)
  ->status_is(200)
  ->json_is('/user/name', 'Joe Doe')
  ->json_is('/user/email', 'mail1@ufal.mff.cuni.cz');

$t->get_ok($shibboleth_url . "?loc=$loc" => {
  'Shib-Session-Id' => '_2690af500207a5891cea6a93eed1fd38',
  'Shib-Identity-Provider' => 'https://cas.cuni.cz/idp/shibboleth',
  'Eppn' => '123@cuni.cz',
  'Cn' => 'Joe Doe2',
  'Mail' => 'mail1@ufal.mff.cuni.cz;mail2@ufal.mff.cuni.cz'
})->status_is(302)
  ->header_like(Location => qr/$loc#success/);

$t->get_ok($auth_check_url)
  ->status_is(200)
  ->json_is('/user/name', 'Joe Doe2')
  ->json_is('/user/email', 'mail1@ufal.mff.cuni.cz');

logout();

$t->get_ok($shibboleth_url . "?loc=$loc" => {
  'Shib-Session-Id' => '_2690af500207a5891cea6a93eed1fd38',
  'Shib-Identity-Provider' => 'https://cas.cuni.cz/idp/shibboleth',
  'Eppn' => '123@cuni.cz'
})->status_is(302)
  ->header_like(Location => qr/$loc#success/);

$t->get_ok($auth_check_url)
  ->status_is(200)
  ->json_is('/user/name', 'Joe Doe2')
  ->json_is('/user/email', 'mail1@ufal.mff.cuni.cz');

logout();

$t->get_ok($shibboleth_url . "?loc=$loc" => {
  'Shib-Session-Id' => '_2690af500207a5891cea6a93eed1fd38',
  'Shib-Identity-Provider' => 'some other org',
  'Eppn' => '123@cuni.cz',
  'Cn' => 'Joe Doe3',
  'Mail' => 'mail1@ufal.mff.cuni.cz;mail2@ufal.mff.cuni.cz'
})->status_is(302)
  ->header_like(Location => qr/$loc#success/);

$t->get_ok($auth_check_url)
  ->status_is(200)
  ->json_is('/user/name', 'Joe Doe3')
  ->json_is('/user/email', 'mail1@ufal.mff.cuni.cz');

# Check if Shibboleth users can access treebanks

logout();

my $test_tb = test_treebank();
my $test_user = test_user();
$test_tb->is_free(0);
$test_tb->update;

my $treebank_url = $t->app->url_for('treebank', treebank_id => $test_tb->id);
my $auth_sign_in_url = $t->app->url_for('auth_sign_in');

$t->get_ok($treebank_url)
  ->status_is(401);

$t->post_ok($auth_sign_in_url => json => {
  auth => {
    username => 'tester',
    password => 'tester'
  }
})->status_is(200);

$t->get_ok($treebank_url)
  ->status_is(403);

logout();

$t->get_ok($shibboleth_url . "?loc=$loc" => {
  'Shib-Session-Id' => '_2690af500207a5891cea6a93eed1fd38',
  'Shib-Identity-Provider' => 'some other org',
  'Eppn' => 'blabla@cuni.cz',
  'Cn' => 'Joe Treebank',
  'Mail' => 'mail1@ufal.mff.cuni.cz;mail2@ufal.mff.cuni.cz'
})->status_is(302)
  ->header_like(Location => qr/$loc#success/);

$t->get_ok($treebank_url)
  ->status_is(200);

done_testing();
