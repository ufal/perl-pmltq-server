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

my $t = test_app();
my $tu = test_user();

ok $t->app->routes->find('auth_check'), 'Auth check route exists';
my $auth_check_url = $t->app->url_for('auth_check');
ok ($auth_check_url, 'Has auth check url');

$t->get_ok($auth_check_url)
  ->status_is(200)
  ->json_is('/user', Mojo::JSON->false);

ok $t->app->routes->find('auth_sign_in'), 'Auth sign in route exists';
my $auth_sign_in_url = $t->app->url_for('auth_sign_in');
ok ($auth_sign_in_url, 'Has auth sign in url');

my @invalid_inputs = (
{},
{ auth => {username => '', password => ''} },
{ auth => {username => 'asdfs' }},
{ auth => {username => 'asdfs', password => 'asdfs' }},
{ auth => {username => 'admin', password => '' }},
{ auth => {username => '', password => 'admin' }},
{ auth => {username => 'asdfs', password => 'admin' }},
);

for my $input (@invalid_inputs) {
  $t->post_ok($auth_sign_in_url => json => $input)
    ->status_is(400)
    ->json_like('/error' => qr/invalid/i);
}

$t->post_ok($auth_sign_in_url => json => {
  auth => {
    username => 'admin',
    password => 'admin'
  }
})->status_is(200)
  ->json_like('/user/username' => qr/admin/)
  ->json_is('/user/password' => undef) # must be empty
  ->json_has('/user/permissions')
  ->json_has('/user/available_treebanks');

my $user = $t->tx->res->json->{user};
ok($user, 'Got user data from the last request');

ok(any { $_->{name} eq 'admin' } @{$user->{permissions}}, 'Has admin permission');

$t->get_ok($auth_check_url)
  ->status_is(200)
  ->json_like('/user/username' => qr/admin/)
  ->json_is('/user/password' => undef) # must be empty
  ->json_has('/user/permissions')
  ->json_has('/user/available_treebanks');

ok $t->app->routes->find('auth_sign_out'), 'Auth sign out route exists';
my $auth_sign_out_url = $t->app->url_for('auth_sign_out');
ok ($auth_sign_out_url, 'Has auth sign out url');

$t->delete_ok($auth_sign_out_url)
  ->status_is(200)
  ->json_is('/' => undef);

$t->get_ok($auth_check_url)
  ->status_is(200)
  ->json_is('/user', Mojo::JSON->false);

done_testing();
