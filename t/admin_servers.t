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

my $create_server_url = $t->app->url_for('create_server');
ok ($create_server_url, 'Create server url exists');

my $test_server = {
  name => 'pmltq_server',
  host => 'localhost',
  port => 1234,
  username => 'ufal',
  password => 'password'
};

$t->post_ok($create_server_url => json => $test_server)
  ->status_is(200);

my $list_servers_url = $t->app->url_for('list_servers');
ok ($list_servers_url, 'List servers url exists');

$t->get_ok($list_servers_url)
  ->status_is(200);

$t->json_is("/0/$_", $test_server->{$_}) for keys %{$test_server};

ok (@{$t->tx->res->json} == 1, 'One server is in the list');

$t->post_ok($create_server_url => json => $test_server)
  ->status_is(400)
  ->json_is('/error', 'server name already exists');

my $update_server_url = $t->app->url_for('update_server', server_id => 1);
ok ($update_server_url, 'Update server url exists');

$test_server->{name} = 'Other name';
$t->put_ok($update_server_url => json => $test_server)
  ->status_is(200)
  ->json_is('/name', $test_server->{name});

done_testing();
