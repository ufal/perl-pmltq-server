use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Test::Deep;

use Mojo::URL;
use File::Basename 'dirname';
use File::Spec;

use List::Util 'first';

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


my $new_users_url = $t->app->url_for('new_users');
ok ($new_users_url, 'New users url exists');

$t->get_ok($new_users_url)
  ->status_is(200);

my $create_users_url = $t->app->url_for('create_users');
ok ($create_users_url, 'Create users url exists');

my %user_data = (
  users => 'Joe User;joe@user.com'
);

$t->post_ok($create_users_url => form => {
  map { ("user.$_" => $user_data{$_}) } keys %user_data
})->status_is(200);


my $user_joe = $t->app->mandel->collection('user')->search({name => 'Joe User'})->single;
ok ($user_joe, 'Joe User is in the database');




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
$user_data{'available_treebanks.0'} = $tb1->id;
$user_data{'available_treebanks.1'} = $tb2->id;

$t->post_ok($create_users_url => form => {
  map { ("user.$_" => $user_data{$_}) } keys %user_data
})->status_is(200);


my $users = $t->app->mandel->collection('user')->search({name => 'Joe User'})->all;
ok (@$users == 2, 'Two Joe Users are in the database');
my $second_joe = first {not $_->id eq $user_joe->id} @$users;
ok(cmp_deeply($second_joe->available_treebanks, subsetof($tb1,$tb2)), 'All treebanks added');

## ====================== stickers ===================
add_stickers(["A","comment a",undef],["B","comment b",0],["C","comment c",1],["D","comment d",0],["X","comment X",undef]);
my $stickers = $t->app->mandel->collection('sticker')->search()->all;

$user_data{'stickers'} = join(",",map {$stickers->[$_]->id} (2,3,4));
$t->post_ok($create_users_url => form => {
  map { ("user.$_" => $user_data{$_}) } keys %user_data
})->status_is(200);
$users = $t->app->mandel->collection('user')->search({name => 'Joe User'})->all;
ok (@$users == 3, 'Three Joe Users are in the database');
my $third_joe = first {not ($_->id eq $user_joe->id or $_->id eq $second_joe->id )} @$users;
ok(cmp_deeply($third_joe->stickers, [$stickers->[2],$stickers->[3],$stickers->[4]]), 'Stickers to third Joe added');

## ================ adding multiple users with group sticker, stickers and treebanks ===================

my %multiuser_data = (
    'user.users' => join("\n",map {$_.";".lc($_).'@mail.com'} qw/A B C/),
    'user.stickers' =>  $stickers->[4]->id,
    'sticker.name' => 'GROUP',
    'sticker.parent' => $stickers->[0]->id
  );
$t->post_ok($create_users_url => form => { %multiuser_data })->status_is(200);  
my $group_sticker = $t->app->mandel->collection('sticker')->search({name => 'GROUP'})->single;
ok($group_sticker, "GROUP sticker added");
is($group_sticker->parent->id, $stickers->[0]->id, "GROUP sticker has correct parent");

$users = [grep {first {$_->name eq 'GROUP'} @{$_->stickers // []}} @{$t->app->mandel->collection('user')->search()->all}];
ok (@$users == 3, 'Three Users with GROUP sticker are in the database');

$users = [grep {first {$_->name eq 'GROUP' } @{$_->stickers // []}
                and first {$_->name eq $stickers->[4]->name } @{$_->stickers // []} } @{$t->app->mandel->collection('user')->search()->all}];
ok (@$users == 3, 'Three Users with GROUP and '.$stickers->[4]->name.' sticker are in the database');

## ========== sticker colision ===============
%multiuser_data = (
    'user.users' => join("\n",map {$_.";".lc($_).'@mail.com'} qw/X/),
    'sticker.name' => 'GROUP',
  );
$t->post_ok($create_users_url => form => { %multiuser_data })
  ->status_is(400)
  ->content_like(qr/\QSticker GROUP already exists/);  
is($t->app->mandel->collection('sticker')->search({name => 'GROUP'})->count,1,"There is only one sticker named GROUP");
 
## ========== invalid users textarea format ========
$multiuser_data{'user.users'}='aa;a@sdsd@';
$t->post_ok($create_users_url => form => { %multiuser_data })
  ->status_is(400);
$multiuser_data{'user.users'}='aa;a@sdsd';
$t->post_ok($create_users_url => form => { %multiuser_data })
  ->status_is(400);
$multiuser_data{'user.users'}='aa;a@sdsd.com
aa';
$t->post_ok($create_users_url => form => { %multiuser_data })
  ->status_is(400);
done_testing();
