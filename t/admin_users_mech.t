use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Test::WWW::Mechanize::Mojo;
use HTML::Lint::Pluggable;
use Mojo::DOM;

use File::Basename 'dirname';
use List::Util 'first';

use lib dirname(__FILE__);

require 'bootstrap.pl';

my $t = test_app();

my $lint = HTML::Lint::Pluggable->new;
$lint->load_plugins(qw/HTML5/);

my $mech = Test::WWW::Mechanize::Mojo->new(tester => $t, autolint => $lint);

$mech->get_ok('/');
$mech->title_like(qr/Please Sign In/);
$mech->html_lint_ok('Login page html is ok');

$mech->submit_form_ok({
  form_name => 'auth',
  fields => {
    'auth.username' => 'admin',
    'auth.password' => 'admin'
  }
}, 'Login form ok');

$mech->title_like(qr/Overview/i);
$mech->html_lint_ok('Overview page html is ok');
$mech->follow_link_ok({ text_regex => qr/users/i }, 'Click on Users');

$mech->title_like(qr/List of Users/i);
$mech->html_lint_ok('List of users html is ok');

$mech->follow_link_ok({ text_regex => qr/add new user/i }, 'Click on Add new user');
$mech->html_lint_ok('User form html is ok');

$mech->submit_form(
  form_name => 'user'
);

is($mech->status, 400, 'Empty form failed');

$mech->submit_form(
  form_name => 'user',
  fields => {
    'user.name' => 'Name is not enough'
  }
);

is($mech->status, 400, 'Required fields not filled');
is($mech->value('user.name'), 'Name is not enough');

$mech->submit_form(
  form_name => 'user',
  fields => {
    'user.name' => 'Joe Tester',
    'user.username' => 'joet',
    'user.password' => 'tester',
    'user.password_confirm' => 'tester123'
  }
);

is($mech->status, 400, 'Required fields not filled');
$mech->text_contains("Passwords don't match", 'Password error');

$mech->submit_form_ok({
  form_name => 'user',
  fields => {
    'user.name' => 'Joe Tester',
    'user.username' => 'joet',
    'user.password' => 'tester',
    'user.password_confirm' => 'tester'
  }  
}, 'Add user without error');

#$mech->title_like(qr/List of Users/i, 'We are the list of users');
#$mech->text_contains('Joe Tester', 'New user is in the list');
#$mech->follow_link_ok({ text_regex => qr/Joe Tester/i }, 'Show user detail');
$mech->title_like(qr/Edit User/i, 'Edit form');

is($mech->value('user.name'), 'Joe Tester', 'Name is ok');
is($mech->value('user.username'), 'joet', 'Username is ok');
is($mech->value('user.password'), '', 'Password is empty');

my $dom = Mojo::DOM->new($mech->content);
my $admin_checkbox = $dom->find('label')->grep(sub { $_->content =~ qr/ admin/ })->first;
$admin_checkbox = $admin_checkbox->attr('for') if $admin_checkbox;

ok ($admin_checkbox, 'Have admin permission checkbox');

my $input = first { $_->id eq $admin_checkbox } $mech->find_all_inputs(
  type       => 'checkbox',
  name_regex => qr/^user.permission/,
);

ok ($input, 'Found input');
ok (!$input->value, 'Not checked');
$input->check;

$mech->submit_form_ok({
  form_name => 'user'
}, 'Add admin permission');

$input = first { $_->id eq $admin_checkbox } $mech->find_all_inputs(
  type       => 'checkbox',
  name_regex => qr/^user.permission/,
);

ok($input->value, 'Checked');

$mech->follow_link_ok({ text_regex => qr/logout/i }, 'Logout user');
$mech->title_like(qr/Please Sign In/);

$mech->submit_form_ok({
  form_name => 'auth',
  fields => {
    'auth.username' => 'joet',
    'auth.password' => 'tester'
  }
}, 'Login form ok');

$mech->title_like(qr/Overview/i);

done_testing();