use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::JSON qw(decode_json encode_json);;
use Test::Deep;
use File::Basename 'dirname';
use File::Spec;

use lib dirname(__FILE__);

require 'bootstrap.pl';

start_postgres();
my $t = test_app();
my $ta = test_admin();
my $tu = test_user();
my $tt = test_treebank();

$t->reset_session();
ok $t->app->routes->find('auth_check'), 'Auth check route exists';
my $auth_check_url = $t->app->url_for('auth_check');
ok ($auth_check_url, 'Has auth check url');

$t->get_ok($auth_check_url)
  ->status_is(200)
  ->json_is('/user', Mojo::JSON->false);

$auth_check_url->userinfo('admin:admin');
$t->get_ok($auth_check_url)
  ->status_is(200)
  ->json_like('/user/username' => qr/admin/)
  ->json_is('/user/password' => undef) # must be empty;
  ->json_has('/user/availableTreebanks');

$auth_check_url->userinfo('tester:tester');
$t->get_ok($auth_check_url)
  ->status_is(200)
  ->json_like('/user/username' => qr/tester/)
  ->json_is('/user/password' => undef) # must be empty;
  ->json_has('/user/availableTreebanks');

$auth_check_url = $t->app->url_for('auth_check'); # clear user info
$t->get_ok($auth_check_url)
  ->status_is(200)
  ->json_like('/user/username' => qr/tester/);

$auth_check_url->userinfo('fake:user');
$t->get_ok($auth_check_url)
  ->status_is(200)
  ->json_like('/user/username' => qr/tester/);

# Restrict access to test treebank
$t->reset_session();
ok $tt->is_free, 'Test treebank can be access by public';
ok $tt->is_all_logged, 'Test treebank can access all logged users';

ok $t->app->routes->find('treebank'), 'Treebank api route exists';
my $treebank_url = $t->app->url_for('treebank', treebank_id => $tt->id);
ok ($treebank_url, 'Treebank has url');

$t->get_ok($treebank_url)
  ->status_is(200);

my $m = decode_json(encode_json($tt->metadata));
ok(cmp_deeply($m, $t->tx->res->json));

$tt->is_free(0); # Disable anonymouse flag
$tt->update();
ok !$tt->is_free, 'Test treebank cannot be access by public';

$t->get_ok($treebank_url)
  ->status_is(401);

$treebank_url->userinfo('admin:admin');
$t->get_ok($treebank_url)
  ->status_is(200);

# Subsequent request should work
$treebank_url = $t->app->url_for('treebank', treebank_id => $tt->id);
$t->get_ok($treebank_url)
  ->status_is(200);

$t->reset_session();
$t->get_ok($treebank_url)
  ->status_is(401);

$t->reset_session();
$treebank_url = $t->app->url_for('treebank', treebank_id => $tt->id);
$treebank_url->userinfo('tester:tester');
$t->get_ok($treebank_url)
  ->status_is(200);

$tt->is_all_logged(0); # Disable anonymouse flag
$tt->update();
ok !$tt->is_all_logged, 'Test treebank cannot be access by all loged users';

$t->reset_session();
$treebank_url = $t->app->url_for('treebank', treebank_id => $tt->id);
$treebank_url->userinfo('tester:tester');
$t->get_ok($treebank_url)
  ->status_is(403);

$tu->access_all(1);
$tu->update();

$treebank_url = $t->app->url_for('treebank', treebank_id => $tt->id);
$t->get_ok($treebank_url)
  ->status_is(200);

$t->reset_session();
$treebank_url = $t->app->url_for('treebank', treebank_id => $tt->id);
$t->get_ok($treebank_url)
  ->status_is(401);

$treebank_url = $t->app->url_for('treebank', treebank_id => $tt->id);
$treebank_url->userinfo('tester:tester');
$t->get_ok($treebank_url)
  ->status_is(200);

done_testing();
