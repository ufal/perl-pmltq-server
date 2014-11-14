use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Test::Deep;

use Mojo::URL;
use File::Basename 'dirname';
use File::Spec;

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
$t->post_ok($t->app->url_for('admin_login') => form => {
  username => $tu->username,
  password => 'tester'
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
  password_confirm => 's3cret',
  email => 'joe@example.com',
);

$t->post_ok($create_user_url => form => {
  map { ("user.$_" => $user_data{$_}) } keys %user_data
})->status_is(200);

$t->post_ok($create_user_url => form => {
  map { ("user.$_" => $user_data{$_}) } keys %user_data
})->status_is(400)
  ->content_like(qr/\QUsername &#39;joe&#39; already exists/);

my $user_joe = $t->app->mandel->collection('user')->search({username => 'joe'})->single;
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


## =========== treebanks  ==================
my %treebank_data = (
  name => 'My treebank',
  title => 'TB',
  driver => 'Pg',
  host => '127.0.0.1',
  port => 5000,
  database => 'mytb',
  username => 'joe',
  password => 's3cret'
);

$t->post_ok($t->app->url_for('create_treebank') => form => {
  map { ("treebank.$_" => $treebank_data{$_}) } keys %treebank_data
})->status_is(200);
my $tb1 = $t->app->mandel->collection('treebank')->search({name => 'My treebank'})->single;
$treebank_data{name} = 'My treebank 2';
$t->post_ok($t->app->url_for('create_treebank') => form => {
  map { ("treebank.$_" => $treebank_data{$_}) } keys %treebank_data
})->status_is(200);
my $tb2 = $t->app->mandel->collection('treebank')->search({name => 'My treebank'})->single;
$user_data{'available_treebanks.0'} = $tb1->id,
$user_data{'available_treebanks.1'} = $tb2->id,

$t->put_ok($update_user_url => form => {
  map { ("user.$_" => $user_data{$_}) } keys %user_data
})->status_is(200);
$updated_joe = $t->app->mandel->collection('user')->search({_id => $user_joe->id})->single;
ok ($updated_joe, 'Joe is still in the database');
ok(cmp_deeply($updated_joe->available_treebanks, subsetof($tb1,$tb2)), 'All treebanks added');
delete $user_data{'available_treebanks.0'};
delete $user_data{'available_treebanks.1'};
$t->put_ok($update_user_url => form => {
  map { ("user.$_" => $user_data{$_}) } keys %user_data
})->status_is(200);

$updated_joe = $t->app->mandel->collection('user')->search({_id => $user_joe->id})->single;
ok ($updated_joe, 'Joe is still in the database');
is(@{$updated_joe->available_treebanks}, 0, 'All treebanks were deleted from user');

## ====================== stickers ===================
add_stickers(["A","comment a",undef],["B","comment b",0],["C","comment c",1],["D","comment d",0],["X","comment X",undef]);
my $stickers = $t->app->mandel->collection('sticker')->search()->all;
$user_data{'stickers'} = join(",",map {$stickers->[$_]->id} (2,3,4));
$t->put_ok($update_user_url => form => {
  map { ("user.$_" => $user_data{$_}) } keys %user_data
})->status_is(200);

$updated_joe = $t->app->mandel->collection('user')->search({_id => $user_joe->id})->single;
ok ($updated_joe, 'Joe is still in the database');

ok(cmp_deeply($updated_joe->stickers, [$stickers->[2],$stickers->[3],$stickers->[4]]), 'All stickers added');
delete $user_data{'stickers'};
$t->put_ok($update_user_url => form => {
  map { ("user.$_" => $user_data{$_}) } keys %user_data
})->status_is(200);

$updated_joe = $t->app->mandel->collection('user')->search({_id => $user_joe->id})->single;
ok ($updated_joe, 'Joe is still in the database');
is(@{$updated_joe->available_treebanks}, 0, 'All stickers were deleted from user');


# ==================== delete user ==================
$t->ua->max_redirects(0);
my $delete_user_url = $t->app->url_for('delete_user', id => $user_joe->id);
ok ($delete_user_url, 'Delete user url exists');
$t->delete_ok($delete_user_url)
  ->status_is(302);

my $deleted_joe = $t->app->mandel->collection('user')->search({_id => $user_joe->id})->single;
ok (!$deleted_joe, 'Joe is gone from the database');

done_testing();
