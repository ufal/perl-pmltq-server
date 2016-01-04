use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Test::Deep;
use Mojo::URL;
use Mojo::JSON;
use File::Basename 'dirname';
use File::Spec;
use List::Util qw(first);

use lib dirname(__FILE__);
require 'bootstrap.pl';

my $t = test_app();
my $admin = test_admin();

# Login
$t->reset_session();
$t->post_ok($t->app->url_for('auth_sign_in') => json => {
  auth => {
    username => 'admin',
    password => 'admin'
  }
})->status_is(200);

# Testing
my $create_language_url = $t->app->url_for('create_language');
ok ($create_language_url, 'Create language url exists');

my $language_group = test_db()->resultset('LanguageGroup')->first();
my $language = {
  languageGroupId => $language_group->id,
  code => 'ts',
  name => 'Test',
};

$t->post_ok($create_language_url => json => $language)
  ->status_is(200);

$t->json_is("/$_", $language->{$_}) for keys %{$language};

my $language_id = $t->tx->res->json->{id};

my $list_languages_url = $t->app->url_for('list_languages');
ok ($list_languages_url, 'List languages url exists');

$t->get_ok($list_languages_url)
  ->status_is(200);

$t->post_ok($create_language_url => json => $language)
  ->status_is(400)
  ->json_is('/error', 'language code already exists');

my $update_language_url = $t->app->url_for('update_language', language_id => $language_id);
ok ($update_language_url, 'Update language url exists');

$language->{name} = 'Other name';
$t->put_ok($update_language_url => json => $language)
  ->status_is(200)
  ->json_is('/name', $language->{name});

done_testing();
