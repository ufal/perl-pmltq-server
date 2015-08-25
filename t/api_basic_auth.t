use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::JSON;
use Test::Deep;
use File::Basename 'dirname';
use File::Spec;
use PMLTQ::Server::Model::Permission ':constants';

use lib dirname(__FILE__);

require 'bootstrap.pl';

start_postgres();
my $t = test_app();
my $ta = test_admin();
my $tu = test_user();
my $tt = test_treebank();

# Restrict access to test treebank

ok $tt->anonaccess, 'Test treebank can be access by public';

ok $t->app->routes->find('treebank'), 'Treebank api route exists';
my $treebank_url = $t->app->url_for('treebank', treebank_id => $tt->id);
ok ($treebank_url, 'Treebank has url');

$t->get_ok($treebank_url)
  ->status_is(200);

my $m = $tt->metadata;
$m->{id} = $m->{id}->to_string;
$m->{access} = Mojo::JSON->true;

ok(cmp_deeply($m, $t->tx->res->json));

$tt->anonaccess(Mojo::JSON->false); # Disable anonymouse flag
$tt->save();
ok !$tt->anonaccess, 'Test treebank cannot be access by public';

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
  ->status_is(403);

my $all_treebanks_perm = $t->app->mandel->collection('permission')->search({name => ALL_TREEBANKS})->single;

$tu->push_permissions($all_treebanks_perm);

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
