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


my $admin_permission = $t->app->mandel->collection('permission')->search({name=>"admin"})->single;
$tu->push_permissions($admin_permission);

# Login
$t->ua->max_redirects(10);
$t->ua->cookie_jar(Mojo::UserAgent::CookieJar->new);
$t->post_ok($t->app->url_for('admin_login') => form => {
  username => $tu->username,
  password => 'tester'
})->status_is(200);

my $list_stickers_url = $t->app->url_for('list_stickers');
ok ($list_stickers_url, 'List stickers url exists');

$t->get_ok($list_stickers_url)
  ->status_is(200);

my $new_sticker_url = $t->app->url_for('new_sticker');
ok ($new_sticker_url, 'New sticker url exists');

$t->get_ok($new_sticker_url)
  ->status_is(200);

my $create_sticker_url = $t->app->url_for('create_sticker');
ok ($create_sticker_url, 'Create sticker url exists');

my %sticker_data = (
  name => 'A',
  comment => 'comment a',
);

$t->post_ok($create_sticker_url => form => {
  map { ("sticker.$_" => $sticker_data{$_}) } keys %sticker_data
})->status_is(200);

$t->post_ok($create_sticker_url => form => {
  map { ("sticker.$_" => $sticker_data{$_}) } keys %sticker_data
})->status_is(400)
  ->content_like(qr/\Qname &#39;A&#39; already exists/);

my $sticker_A = $t->app->mandel->collection('sticker')->search({name => 'A'})->single;
ok ($sticker_A, 'A is in the database');

my $show_sticker_url = $t->app->url_for('show_sticker', id => $sticker_A->id);
ok ($show_sticker_url, 'Show url exists');

$t->get_ok($show_sticker_url)
  ->status_is(200);

my $update_sticker_url = $t->app->url_for('update_sticker', id => $sticker_A->id);
ok ($update_sticker_url, 'Update sticker url exists');

$sticker_data{name} = 'A Updated';

$t->put_ok($update_sticker_url => form => {
  map { ("sticker.$_" => $sticker_data{$_}) } keys %sticker_data
})->status_is(200);

my $updated_A = $t->app->mandel->collection('sticker')->search({_id => $sticker_A->id})->single;
ok ($updated_A, 'A is still in the database');
isnt ($updated_A->name, $sticker_A->name, 'Name has got updated');
is ($updated_A->comment, $sticker_A->comment, 'Comment has not changed');


my %sticker_dataB = (
  name => 'B',
  comment => 'comment b',
  parent => $sticker_A->id
);

$t->post_ok($create_sticker_url => form => {
  map { ("sticker.$_" => $sticker_dataB{$_}) } keys %sticker_dataB
})->status_is(200);

my $sticker_B = $t->app->mandel->collection('sticker')->search({name => 'B'})->single;
ok ($sticker_B, 'B is in the database');
is ($sticker_B->parent->id,$sticker_A->id, 'A is parent sticker of B');

$update_sticker_url = $t->app->url_for('update_sticker', id => $sticker_A->id);
ok ($update_sticker_url, 'Update sticker url exists');

$sticker_data{parent} = $sticker_A->id; # cycle in stickers graph is not allowed !!!

$t->put_ok($update_sticker_url => form => {
  map { ("sticker.$_" => $sticker_data{$_}) } keys %sticker_data
})->status_is(400)
  ->content_like(qr/\Qsticker structure is not tree/);


$t->ua->max_redirects(0);
my $delete_sticker_url = $t->app->url_for('delete_sticker', id => $sticker_A->id);
ok ($delete_sticker_url, 'Delete sticker url exists');
$t->delete_ok($delete_sticker_url)
  ->status_is(302);

my $deleted_A = $t->app->mandel->collection('sticker')->search({_id => $sticker_A->id})->single;
ok (!$deleted_A, 'A is gone from the database');





done_testing();
