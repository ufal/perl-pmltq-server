use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::JSON;
use File::Basename 'dirname';

use lib dirname(__FILE__);

require 'bootstrap.pl';

my $t = test_app();
my $tu = test_user();

ok $t->app->routes->find('auth_sign_in'), 'Auth sign in route exists';
my $auth_sign_in_url = $t->app->url_for('auth_sign_in');
ok ($auth_sign_in_url, 'Has auth sign in url');

# Can't access admin api as a user
my $list_treebanks_url = $t->app->url_for('list_treebanks');
ok ($list_treebanks_url, 'List treebanks url exists');

$t->reset_session();
$t->get_ok($list_treebanks_url)
  ->status_is(401);

$t->post_ok($auth_sign_in_url => json => {
  auth => {
    username => 'tester',
    password => 'tester'
  }
})->status_is(200);

$t->get_ok($list_treebanks_url)
  ->status_is(403);

$tu->is_admin(1);
$tu->update;

$t->get_ok($list_treebanks_url)
  ->status_is(200);

done_testing();
