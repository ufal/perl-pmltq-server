use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::URL;
use Mojo::UserAgent::CookieJar;
use File::Basename 'dirname';
use File::Spec;

use lib dirname(__FILE__);

require 'bootstrap.pl';

my $t = test_app();
my $tu = test_user();

$t->ua->max_redirects(10);

ok $t->app->routes->find('auth'), 'Auth route exists';
my $auth_url = $t->app->url_for('admin_login');
ok ($auth_url, 'Has auth url');

$t->ua->cookie_jar(Mojo::UserAgent::CookieJar->new);
$t->post_ok($auth_url => form => { })->status_is(400);

$t->ua->cookie_jar(Mojo::UserAgent::CookieJar->new);
$t->post_ok($auth_url => form => {
  'auth.username' => 'blah',
})->status_is(400);

$t->ua->cookie_jar(Mojo::UserAgent::CookieJar->new);
$t->post_ok($auth_url => form => {
  'auth.password' => 'blah',
})->status_is(400);

$t->ua->cookie_jar(Mojo::UserAgent::CookieJar->new);
$t->post_ok($auth_url => form => {
  'auth.username' => $tu->username,
  'auth.password' => 'tester'
})->status_is(404);

my $admin_permission = $t->app->mandel->collection('permission')->create({
  name => 'admin',
  comment => 'All powerfull admin'
});
$admin_permission->save();

$tu->push_permissions($admin_permission);

$t->ua->cookie_jar(Mojo::UserAgent::CookieJar->new);
$t->post_ok($auth_url => form => {
  'auth.username' => $tu->username,
  'auth.password' => 'tester'
})->status_is(200);

done_testing();
