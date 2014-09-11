use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::URL;
use File::Basename 'dirname';
use File::Spec;
use Data::Dumper;

use lib dirname(__FILE__);

require 'bootstrap.pl';

my $t = test_app();
my $tu = test_user();

my $admin_permission = $t->app->mandel->collection('permission')->create({
  name => 'admin',
  comment => 'All powerfull admin'
});
$admin_permission->save();

$tu->push_permissions($admin_permission);

# Login
$t->ua->max_redirects(10);
$t->ua->cookie_jar(Mojo::UserAgent::CookieJar->new);
$t->post_ok($t->app->url_for('auth_login') => form => {
  username => $tu->username,
  password => $tu->password
})->status_is(200);

my $list_users_url = $t->app->url_for('list_users');
ok ($list_users_url, 'List users url exists');

$t->get_ok($list_users_url)
  ->status_is(200);

my $new_user_url = $t->app->url_for('new_user');
ok ($new_user_url, 'New user url exists');

$t->get_ok($new_user_url)
  ->status_is(200);

my $create_user_url = $t->app->url_for('create_user');
ok ($create_user_url, 'Create user url exists');

my $show_user_url = $t->app->url_for('show_user');
ok ($show_user_url, 'Show url exists');

my $update_user_url = $t->app->url_for('update_user');
ok ($update_user_url, 'Update user url exists');

my $delete_user_url = $t->app->url_for('delete_user');
ok ($delete_user_url, 'Delete user url exists');



done_testing();
