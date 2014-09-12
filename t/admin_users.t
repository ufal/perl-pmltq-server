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

my %user_data = (
  name => 'Joe Tester',
  username => 'joe',
  password => 's3cret',
  email => 'joe@example.com',
);

$t->post_ok($create_user_url => form => {
  map { ("user.$_" => $user_data{$_}) } keys %user_data
})->status_is(200);

my $user_joe = $t->app->mandel->collection('user')->search({username => 'joe', password => 's3cret'})->single;
ok ($user_joe, 'Joe is in the database');

my $show_user_url = $t->app->url_for('show_user', id => $user_joe->id);
ok ($show_user_url, 'Show url exists');

$t->get_ok($show_user_url)
  ->status_is(200);

my $update_user_url = $t->app->url_for('update_user', id => $user_joe->id);
ok ($update_user_url, 'Update user url exists');

$user_data{name} = 'Joe Updated';

$t->put_ok($update_user_url => form => {
  map { ("user.$_" => $user_data{$_}) } keys %user_data
})->status_is(200);

my $updated_joe = $t->app->mandel->collection('user')->search({_id => $user_joe->id})->single;
ok ($updated_joe, 'Joe is still in the database');
isnt ($updated_joe->name, $user_joe->name, 'Name has got updated');
is ($updated_joe->email, $user_joe->email, 'Email has not changed');

$t->ua->max_redirects(0);
my $delete_user_url = $t->app->url_for('delete_user', id => $user_joe->id);
ok ($delete_user_url, 'Delete user url exists');
$t->delete_ok($delete_user_url)
  ->status_is(302);

my $deleted_joe = $t->app->mandel->collection('user')->search({_id => $user_joe->id})->single;
ok (!$deleted_joe, 'Joe is gone from the database');

done_testing();
