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

my $create_sticker_url = $t->app->url_for('create_sticker');

my %sticker_dataA = (
  name => 'A',
  comment => 'comment a',
);

$t->post_ok($create_sticker_url => form => {
  map { ("sticker.$_" => $sticker_dataA{$_}) } keys %sticker_dataA
})->status_is(200);

my $sticker_A = $t->app->mandel->collection('sticker')->search({name => 'A'})->single;

my %sticker_dataB = (
  name => 'B',
  comment => 'comment b',
  parent => $sticker_A->id
);

$t->post_ok($create_sticker_url => form => {
  map { ("sticker.$_" => $sticker_dataB{$_}) } keys %sticker_dataB
})->status_is(200);

my $sticker_B = $t->app->mandel->collection('sticker')->search({name => 'B'})->single;

my %sticker_dataC = (
  name => 'C',
  comment => 'comment c',
  parent => $sticker_B->id
);

$t->post_ok($create_sticker_url => form => {
  map { ("sticker.$_" => $sticker_dataC{$_}) } keys %sticker_dataC
})->status_is(200);

my $sticker_C = $t->app->mandel->collection('sticker')->search({name => 'C'})->single;

my %sticker_dataD = (
  name => 'D',
  comment => 'comment c',
  parent => $sticker_B->id
);

$t->post_ok($create_sticker_url => form => {
  map { ("sticker.$_" => $sticker_dataD{$_}) } keys %sticker_dataD
})->status_is(200);

my $sticker_D = $t->app->mandel->collection('sticker')->search({name => 'D'})->single;


###  A
###  +-B
###    +-C
###    +-D
ok ($sticker_A, 'A is in the database');
ok ($sticker_B, 'B is in the database');
ok ($sticker_C, 'C is in the database');
ok ($sticker_D, 'D is in the database');



# deleting all descendant stickers
$t->ua->max_redirects(0);
my $delete_sticker_url = $t->app->url_for('delete_sticker', id => $sticker_B->id);
ok ($delete_sticker_url, 'Delete sticker url exists');
$t->delete_ok($delete_sticker_url)
  ->status_is(302);

my $deleted_A = $t->app->mandel->collection('sticker')->search({_id => $sticker_A->id})->single;
my $deleted_B = $t->app->mandel->collection('sticker')->search({_id => $sticker_B->id})->single;
my $deleted_C = $t->app->mandel->collection('sticker')->search({_id => $sticker_C->id})->single;
my $deleted_D = $t->app->mandel->collection('sticker')->search({_id => $sticker_D->id})->single;
ok ($deleted_A, 'A is in the database');
ok (!$deleted_B, 'B is gone from the database');
ok (!$deleted_C, 'C is gone from the database');
ok (!$deleted_D, 'D is gone from the database');
$t->ua->max_redirects(10);

###
my %sticker_dataX = (
  name => 'X',
  comment => 'comment x',
);

$t->post_ok($create_sticker_url => form => {
  map { ("sticker.$_" => $sticker_dataX{$_}) } keys %sticker_dataX
})->status_is(200);

my $sticker_X = $t->app->mandel->collection('sticker')->search({name => 'X'})->single;
ok ($sticker_X, 'X is in the database');

# treebanks
my $create_treebank_url = $t->app->url_for('create_treebank');
my %treebank_data = (
  title => 'TA',
  driver => 'Pg',
  host => '127.0.0.1',
  port => 5000,
  database => 'mytb',
  username => 'joe',
  password => 's3cret',
  stickers => $sticker_A->id .",".$sticker_X->id
);

$t->post_ok($create_treebank_url => form => { "treebank.name" => 'tA',
  map { ("treebank.$_" => $treebank_data{$_}) } keys %treebank_data
  })->status_is(200);  
my $treebank_A = $t->app->mandel->collection('treebank')->search({name => 'tA'})->single;


$t->post_ok($create_treebank_url => form => { "treebank.name" => 'tB',
  map { ("treebank.$_" => $treebank_data{$_}) } keys %treebank_data
  })->status_is(200);  
my $treebank_B = $t->app->mandel->collection('treebank')->search({name => 'tB'})->single;

ok ($treebank_A, 'treebank tA is in the database');
ok ($treebank_B, 'treebank tB is in the database');

ok (cmp_deeply([map { $_->id }  @{$treebank_A->stickers}],
               bag($sticker_A->id,$sticker_X->id)),'Stickers are correctly saved in treebank tA');
ok (cmp_deeply([map { $_->id }  @{$treebank_B->stickers}],
               bag($sticker_A->id,$sticker_X->id)),'Stickers are correctly saved in treebank tB');


# users
my $create_user_url = $t->app->url_for('create_user');

my %user_data = (
  name => 'Joe Tester',
  password => 's3cret',
  password_confirm => 's3cret',
  email => 'joe@example.com',
  stickers => $sticker_A->id .",".$sticker_X->id
);

$t->post_ok($create_user_url => form => { "user.username" => 'uA',
  map { ("user.$_" => $user_data{$_}) } keys %user_data
  })->status_is(200);  
my $user_A = $t->app->mandel->collection('user')->search({username => 'uA'})->single;

$t->post_ok($create_user_url => form => { "user.username" => 'uB',
  map { ("user.$_" => $user_data{$_}) } keys %user_data
  })->status_is(200);  
my $user_B = $t->app->mandel->collection('user')->search({username => 'uB'})->single;

ok ($user_A, 'user uA is in the database');
ok ($user_B, 'user uB is in the database');

ok (cmp_deeply([map { $_->id }  @{$user_A->stickers}],
               bag($sticker_A->id,$sticker_X->id)),'Stickers are correctly saved in user uA');
ok (cmp_deeply([map { $_->id }  @{$user_B->stickers}],
               bag($sticker_A->id,$sticker_X->id)),'Stickers are correctly saved in user uB');

### remove sticker A
$t->ua->max_redirects(0);
$delete_sticker_url = $t->app->url_for('delete_sticker', id => $sticker_A->id);
ok ($delete_sticker_url, 'Delete sticker url exists');
$t->delete_ok($delete_sticker_url)
  ->status_is(302);

$deleted_A = $t->app->mandel->collection('sticker')->search({_id => $sticker_A->id})->single;
my $deleted_X = $t->app->mandel->collection('sticker')->search({_id => $sticker_X->id})->single;
ok ($deleted_X, 'X is in the database');
ok (!$deleted_A, 'A is gone from the database');
$t->ua->max_redirects(10);

$treebank_A = $t->app->mandel->collection('treebank')->search({name => 'tA'})->single;
$treebank_B = $t->app->mandel->collection('treebank')->search({name => 'tB'})->single;
$user_A = $t->app->mandel->collection('user')->search({username => 'uA'})->single;
$user_B = $t->app->mandel->collection('user')->search({username => 'uB'})->single;

ok (cmp_deeply([map { $_->id }  @{$treebank_A->stickers}],
               bag($sticker_X->id)),'Sticker A is correctly removed from treebank tA');
ok (cmp_deeply([map { $_->id }  @{$treebank_B->stickers}],
               bag($sticker_X->id)),'Sticker A is correctly removed from treebank tB');
ok (cmp_deeply([map { $_->id }  @{$user_A->stickers}],
               bag($sticker_X->id)),'Sticker A is correctly removed from user uA');
ok (cmp_deeply([map { $_->id }  @{$user_B->stickers}],
               bag($sticker_X->id)),'Sticker A is correctly removed from user uB');



done_testing();
