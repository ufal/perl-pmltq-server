use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Test::Deep;
use Mojo::URL;
use File::Basename 'dirname';
use File::Spec;
use Data::Dumper;
use List::Util qw(first);

use lib dirname(__FILE__);
require 'bootstrap.pl';

my @required = qw/name title driver host port database username password/;

my $t = test_app();
my $admin = test_admin();

# Login
$t->ua->max_redirects(10);
$t->ua->cookie_jar(Mojo::UserAgent::CookieJar->new);
$t->post_ok($t->app->url_for('admin_login') => form => {
  username => $admin->username,
  password => 'admin'
})->status_is(200);

######## BASIC FUNCTIONALITY ############

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
  driver => 'Pg',
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
$t->ua->max_redirects(10);

my $deleted_tb = $t->app->mandel->collection('treebank')->search({_id => $treebank_tb->id})->single;
ok (!$deleted_tb, 'My treebank is gone from the database');

######## VALIDATION ############
%treebank_data = (
  name => 'New treebank',
  title => 'TB',
  driver => 'Pg',
  host => '127.0.0.1',
  port => 5000,
  database => 'mytb',
  username => 'joe',
  password => 's3cret'
);

## CREATE - all fields are required

for my $key (@required){
  my @fields = grep {!($key eq $_)} keys(%treebank_data);
  $t->post_ok($t->app->url_for('create_treebank') => form => { map { ("treebank.$_" => $treebank_data{$_}) } @fields})->status_is(400);
}

for my $key (qw/driver port data_sources documentation/){
  my @fields = grep {!($key eq $_)} keys(%treebank_data);
  $t->post_ok($t->app->url_for('create_treebank') => form => {"treebank.$key"=> 'INVALID DATA', map { ("treebank.$_" => $treebank_data{$_}) } @fields})->status_is(400);
}

## UPDATE - almost all fields are required (password is not required)
$treebank_data{data_sources} = "[title1](path/to/data1)\n[title2](path/to/data2)";
$treebank_data{documentation} = "[doc1](http://link.to/data1)\n[doc2](http://link.to/data2)";
$t->post_ok($t->app->url_for('create_treebank') => form => {  map { ("treebank.$_" => $treebank_data{$_}) } keys %treebank_data})->status_is(200);
$treebank_data{name}='Second treebank';
$t->post_ok($t->app->url_for('create_treebank') => form => {  map { ("treebank.$_" => $treebank_data{$_}) } keys %treebank_data})->status_is(200);
$treebank_data{name}='New treebank';

## testing documentation and data_sources insertion
$treebank_tb = $t->app->mandel->collection('treebank')->search({name => 'New treebank'})->single;
ok(cmp_deeply($treebank_tb->data_sources,{title1 => 'path/to/data1', title2 => 'path/to/data2'}),"Testing data_sources");
ok(cmp_deeply($treebank_tb->documentation,[{title => "doc1",link=>'http://link.to/data1'},{title =>'doc2',link => 'http://link.to/data2'}]),"Testing documentation");

## insert treebank with existing name
$t->post_ok($t->app->url_for('create_treebank') => form => {  map { ("treebank.$_" => $treebank_data{$_}) } keys %treebank_data})->status_is(400);

for my $key (@required){
  my @fields = grep {!($key eq $_)} keys(%treebank_data);
  $t->post_ok($t->app->url_for('update_treebank', id => $treebank_tb->id) => form => {  _method=>"PUT", map { ("treebank.$_" => $treebank_data{$_}) } @fields})->status_is($key eq 'password' ? 200 : 400);
}
for my $key (qw/driver port data_sources documentation/){
  my @fields = grep {!($key eq $_)} keys(%treebank_data);
  $t->post_ok($t->app->url_for('update_treebank', id => $treebank_tb->id) => form => {  _method=>"PUT", "treebank.$key"=> 'INVALID DATA', map { ("treebank.$_" => $treebank_data{$_}) } @fields})->status_is(400);
}

## try to update treebank =>  should cause treebank.name colision
$treebank_data{name}='Second treebank';
$t->post_ok($t->app->url_for('update_treebank', id => $treebank_tb->id) => form => {  _method=>"PUT",  map { ("treebank.$_" => $treebank_data{$_}) } keys %treebank_data})->status_is(400);

## test bools
$treebank_data{name}='New Treebank';
$treebank_data{public}=1;
$t->put_ok($t->app->url_for('update_treebank', id => $treebank_tb->id) => form => { map { ("treebank.$_" => $treebank_data{$_}) } keys %treebank_data })->status_is(200);
$updated_tb = $t->app->mandel->collection('treebank')->search({_id => $treebank_tb->id})->single;
ok ($updated_tb->public, 'Public true');
ok (!$updated_tb->anonaccess, 'Anonaccess false');

$treebank_data{public}=1;
$treebank_data{anonaccess}=1;
$t->put_ok($t->app->url_for('update_treebank', id => $treebank_tb->id) => form => { map { ("treebank.$_" => $treebank_data{$_}) } keys %treebank_data })->status_is(200);
$updated_tb = $t->app->mandel->collection('treebank')->search({_id => $treebank_tb->id})->single;
ok ($updated_tb->public, 'Public true');
ok ($updated_tb->anonaccess, 'Anonaccess true');

## remove dbref of treebank from user
my $tb_id = $treebank_tb->id;
my $tb2_id = $t->app->mandel->collection('treebank')->search({name => 'Second treebank'})->single->id;

my %user_data = (
  name => 'Joe Tester',
  username => 'joe2',
  password => 's3cret',
  password_confirm => 's3cret',
  email => 'joe@example.com',
  'available_treebanks.0' => $tb_id,
  'available_treebanks.1' => $tb2_id,
);

$t->post_ok($t->app->url_for('create_user') => form => { map { ("user.$_" => $user_data{$_}) } keys %user_data })->status_is(200);
my $user_joe = $t->app->mandel->collection('user')->search({username => 'joe2'})->single;
ok((first {$tb_id eq $_->id} @{$user_joe->available_treebanks}), "Treebank not inserted");

$t->ua->max_redirects(0);
$t->delete_ok($t->app->url_for('delete_treebank', id => $tb_id))->status_is(302);
$t->ua->max_redirects(10);

$user_joe = $t->app->mandel->collection('user')->search({username => 'joe2'})->single;

ok(not(grep { $tb_id eq $_->id } @{$user_joe->available_treebanks}), "dbRef to treebank exists");

done_testing();
