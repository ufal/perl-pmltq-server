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

my $list_treebanks_url = $t->app->url_for('list_treebanks');
ok ($list_treebanks_url, 'List treebanks url exists');

$t->get_ok($list_treebanks_url)
  ->status_is(200);

my $new_treebank_url = $t->app->url_for('new_treebank');
ok ($new_treebank_url, 'New treebank url exists');

$t->get_ok($new_treebank_url)
  ->status_is(200);

my $create_treebank_url = $t->app->url_for('create_treebank');
ok ($create_treebank_url, 'Create treebank url exists');

my %treebank_data = (
  name => 'My treebank',
  title => 'TB',
  driver => 'pg',
  host => '127.0.0.1',
  port => 5000,
  database => 'mytb',
  username => 'joe',
  password => 's3cret'
);

$t->post_ok($create_treebank_url => form => {
  map { ("treebank.$_" => $treebank_data{$_}) } keys %treebank_data
})->status_is(200);

my $treebank_tb = $t->app->mandel->collection('treebank')->search({name => 'My treebank'})->single;
ok ($treebank_tb, 'My treebank is in the database');

my $show_treebank_url = $t->app->url_for('show_treebank', id => $treebank_tb->id);
ok ($show_treebank_url, 'Show url exists');

$t->get_ok($show_treebank_url)
  ->status_is(200);

my $update_treebank_url = $t->app->url_for('update_treebank', id => $treebank_tb->id);
ok ($update_treebank_url, 'Update treebank url exists');

$treebank_data{name} = 'My treebank updated';

$t->put_ok($update_treebank_url => form => {
  map { ("treebank.$_" => $treebank_data{$_}) } keys %treebank_data
})->status_is(200);

my $updated_tb = $t->app->mandel->collection('treebank')->search({_id => $treebank_tb->id})->single;
ok ($updated_tb, 'Joe is still in the database');
isnt ($updated_tb->name, $treebank_tb->name, 'Name has got updated');
is ($updated_tb->title, $treebank_tb->title, 'Title has not changed');

$t->ua->max_redirects(0);
my $delete_treebank_url = $t->app->url_for('delete_treebank', id => $treebank_tb->id);
ok ($delete_treebank_url, 'Delete treebank url exists');
$t->delete_ok($delete_treebank_url)
  ->status_is(302);

my $deleted_tb = $t->app->mandel->collection('treebank')->search({_id => $treebank_tb->id})->single;
ok (!$deleted_tb, 'My treebank is gone from the database');

done_testing();
