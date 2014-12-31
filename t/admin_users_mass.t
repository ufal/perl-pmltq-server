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

my $log = setup_log('info'); # needed to be setted before test_app !!
my $t = test_app();
my $tu = test_user();

my $tmp_templ = 'To: %%TO%%,Subject: %%SUBJECT%%,Body: '.$t->app->config->{mail_templates}->{registration}->{text};
(my $tmp_reg = $tmp_templ) =~ s/%%.*?%%/(.*?)/g;  
$tmp_reg =~ s/\s+/ /g;
my $regTemplate = {
    subject => $t->app->config->{mail_templates}->{registration}->{subject},
    text => $t->app->config->{mail_templates}->{registration}->{text},
    variables => [$tmp_templ =~ m/%%(.*?)%%/g],    
    log_regex => qr/$tmp_reg/
  };
  
my $emails;
my $emails_parsed;

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
start_log($log);
$t->post_ok($create_users_url => form => {
  map { ("user.$_" => $user_data{$_}) } keys %user_data
})->status_is(200);
stop_log($log);

$emails = registration_mail(get_log($log));
$emails_parsed = get_data_from_log($emails);
ok(@$emails == 1,'One registration email has been sended');
ok(@$emails_parsed == 1,'Email has correct format');

my $user_joe = $t->app->mandel->collection('user')->search({name => 'Joe User'})->single;
ok ($user_joe, 'Joe User is in the database');

ok (encrypt_password($emails_parsed->[0]->{PLAIN_PASSWORD}) eq $user_joe->password,'Password in database is equal to hashed password in email');
ok ($emails_parsed->[0]->{USERNAME} eq $user_joe->username,'Username in database is equal to username in email');



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

start_log($log);
$t->post_ok($create_users_url => form => {
  map { ("user.$_" => $user_data{$_}) } keys %user_data
})->status_is(200);
stop_log($log);

$emails = registration_mail(get_log($log));
$emails_parsed = get_data_from_log($emails);
ok(@$emails == 1,'One registration email has been sended');
ok(@$emails_parsed == 1,'Email has correct format');

my $users = $t->app->mandel->collection('user')->search({name => 'Joe User'})->all;
ok (@$users == 2, 'Two Joe Users are in the database');
my $second_joe = first {not $_->id eq $user_joe->id} @$users;
ok(cmp_deeply($second_joe->available_treebanks, subsetof($tb1,$tb2)), 'All treebanks added');

ok (encrypt_password($emails_parsed->[0]->{PLAIN_PASSWORD}) eq $second_joe->password,'Password in database is equal to hashed password in email');
ok ($emails_parsed->[0]->{USERNAME} eq $second_joe->username,'Username in database is equal to username in email');




## ====================== stickers ===================
add_stickers(["A","comment a",undef],["B","comment b",0],["C","comment c",1],["D","comment d",0],["X","comment X",undef]);
my $stickers = $t->app->mandel->collection('sticker')->search()->all;

$user_data{'stickers'} = join(",",map {$stickers->[$_]->id} (2,3,4));

start_log($log);
$t->post_ok($create_users_url => form => {
  map { ("user.$_" => $user_data{$_}) } keys %user_data
})->status_is(200);
stop_log($log);

$emails = registration_mail(get_log($log));
$emails_parsed = get_data_from_log($emails);
ok(@$emails == 1,'Three registration email has been sended');
ok(@$emails_parsed == 1,'Email has correct format');

$users = $t->app->mandel->collection('user')->search({name => 'Joe User'})->all;
ok (@$users == 3, 'Three Joe Users are in the database');
my $third_joe = first {not ($_->id eq $user_joe->id or $_->id eq $second_joe->id )} @$users;
ok(cmp_deeply($third_joe->stickers, [$stickers->[2],$stickers->[3],$stickers->[4]]), 'Stickers to third Joe added');

ok (encrypt_password($emails_parsed->[0]->{PLAIN_PASSWORD}) eq $third_joe->password,'Password in database is equal to hashed password in email');
ok ($emails_parsed->[0]->{USERNAME} eq $third_joe->username,'Username in database is equal to username in email');


## ================ adding multiple users with group sticker, stickers and treebanks ===================

my %multiuser_data = (
    'user.users' => join("\n",map {$_.";".lc($_).'@mail.com'} qw/A B C/),
    'user.stickers' =>  $stickers->[4]->id,
    'sticker.name' => 'GROUP',
    'sticker.parent' => $stickers->[0]->id
  );
start_log($log);
$t->post_ok($create_users_url => form => { %multiuser_data })->status_is(200);  
stop_log($log);

$emails = registration_mail(get_log($log));
$emails_parsed = get_data_from_log($emails);
ok(@$emails == 3,'Three registration email has been sended');
ok(@$emails_parsed == 3,'Email has correct format');

my $group_sticker = $t->app->mandel->collection('sticker')->search({name => 'GROUP'})->single;
ok($group_sticker, "GROUP sticker added");
is($group_sticker->parent->id, $stickers->[0]->id, "GROUP sticker has correct parent");

$users = [grep {first {$_->name eq 'GROUP'} @{$_->stickers // []}} @{$t->app->mandel->collection('user')->search()->all}];
ok (@$users == 3, 'Three Users with GROUP sticker are in the database');

$users = [grep {first {$_->name eq 'GROUP' } @{$_->stickers // []}
                and first {$_->name eq $stickers->[4]->name } @{$_->stickers // []} } @{$t->app->mandel->collection('user')->search()->all}];
ok (@$users == 3, 'Three Users with GROUP and '.$stickers->[4]->name.' sticker are in the database');

ok (cmp_deeply([map { {PASSWORD => encrypt_password($_->{PLAIN_PASSWORD}),USERNAME => $_->{USERNAME} } } @$emails_parsed],
               [(map { {PASSWORD => $_->password, USERNAME => $_->username} } @$users)]),'Password and username are correct in email');

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


sub registration_mail {
  return  [grep {m/registration/} grep {m/\[MAIL\]/} @{shift()}];
}

sub get_data_from_log {
  my $list = shift;
  return  [grep {keys %$_} map {my %hash; @hash{@{$regTemplate->{variables}}} = $_ =~ m/$regTemplate->{log_regex}/;\%hash} @{$list}];
}