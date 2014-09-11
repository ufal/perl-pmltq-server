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

$t->ua->max_redirects(10);
$t->ua->cookie_jar(Mojo::UserAgent::CookieJar->new);
$t->post_ok($t->app->url_for('auth_login') => form => {
  username => $tu->username,
  password => $tu->password
})->status_is(200);

done_testing();
