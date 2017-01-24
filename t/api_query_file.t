use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use File::Basename 'dirname';
use Digest::SHA qw(sha1_hex);
use Mojo::IOLoop;

use lib dirname(__FILE__);

require 'bootstrap.pl';

my $t = test_app();
my $tb = test_treebank();
my $tu = test_user();

$t->reset_session();

ok $t->app->routes->find('auth_sign_in'), 'Auth sign in route exists';
my $auth_sign_in_url = $t->app->url_for('auth_sign_in');
ok ($auth_sign_in_url, 'Has auth sign in url');

ok $t->app->routes->find('create_query_file'), 'Route exists';
my $create_query_file_url = $t->app->url_for('create_query_file');
ok ($create_query_file_url, 'Create query file url exists');

my $query_file = {
  name => 'test_file'
};

$t->post_ok($create_query_file_url => json => $query_file)
  ->status_is(401);

$t->post_ok($auth_sign_in_url => json => {
  auth => {
    username => 'tester',
    password => 'tester'
  }
})->status_is(200);

$t->post_ok($create_query_file_url => json => $query_file)
  ->status_is(200);

ok $t->app->routes->find('list_query_files'), 'Route exists';
my $list_query_files_url = $t->app->url_for('list_query_files');
ok ($list_query_files_url, 'List query files url exists');

$t->get_ok($list_query_files_url)
  ->status_is(200);

$t->json_is("/0/$_", $query_file->{$_}) for keys %{$query_file};

ok (@{$t->tx->res->json} == 1, 'One query file is in the list');

my $fetched_file = $t->tx->res->json->[0];

is ($fetched_file->{userId}, $tu->id, 'User id match');
ok (@{$fetched_file->{queries}} == 0, 'Contains no queries');

ok $t->app->routes->find('update_query_file'), 'Route exists';
my $update_query_file_url = $t->app->url_for('update_query_file', query_file_id => $fetched_file->{id});
ok ($update_query_file_url, 'Update query file url exists');

$fetched_file->{name} = 'Other name';
$t->put_ok($update_query_file_url => json => $fetched_file)
  ->status_is(200)
  ->json_is('/name', $fetched_file->{name});

ok $t->app->routes->find('create_query_file_query'), 'Route exists';
my $create_query_file_queries_url = $t->app->url_for('create_query_file_query', query_file_id => $fetched_file->{id});
ok ($create_query_file_queries_url, 'Create query file query record file url exists');

# Minimal query
my $query_record = {
  query => 'a-node []'
};

$t->post_ok($create_query_file_queries_url => json => $query_record)
  ->status_is(200);

ok $t->app->routes->find('list_query_file_queries'), 'Route exists';
my $list_query_file_queries_url = $t->app->url_for('list_query_file_queries', query_file_id => $fetched_file->{id});
ok ($list_query_file_queries_url, 'List query file queries file url exists');

$t->get_ok($list_query_file_queries_url)
  ->status_is(200);

$t->json_is("/0/$_", $query_record->{$_}) for keys %{$query_record};

ok (@{$t->tx->res->json} == 1, 'One query file is in the list');
my $fetched_query_record = $t->tx->res->json->[0];

ok $t->app->routes->find('get_query_file'), 'Route exists';
my $get_query_file_url = $t->app->url_for('get_query_file', query_file_id => $fetched_file->{id});
ok ($get_query_file_url, 'Get query file url exists');

$t->get_ok($get_query_file_url)
  ->status_is(200);

$t->json_is("/queries/0/$_", $fetched_query_record->{$_}) for keys %{$fetched_query_record};

# add few more queries
for (qw/test1 test2 test3/) {
  $t->post_ok($create_query_file_queries_url => json => {
    name => $_,
    query => "a-node [ attr = '$_' ]"
  })->status_is(200);
}

$t->get_ok($get_query_file_url)
  ->status_is(200);

my $all_queries = $t->tx->res->json->{queries};
ok (@{$all_queries} == 4, 'Has four queries');

ok $t->app->routes->find('get_query_file_query'), 'Route exists';
my $get_query_file_query_url = $t->app->url_for('get_query_file_query', query_file_id => $fetched_file->{id}, query_id => $fetched_query_record->{id});
ok ($get_query_file_query_url, 'Get query file query url exists');

$t->get_ok($get_query_file_query_url)
  ->status_is(200);

$t->json_is("/$_", $fetched_query_record->{$_}) for keys %{$fetched_query_record};

ok $t->app->routes->find('update_query_file_query'), 'Route exists';
my $update_query_file_query_url = $t->app->url_for('update_query_file_query', query_file_id => $fetched_file->{id}, query_id => $fetched_query_record->{id});
ok ($update_query_file_query_url, 'Get query file query url exists');

$fetched_query_record->{name} = 'A name';
$t->put_ok($get_query_file_query_url => json => $fetched_query_record)
  ->status_is(200);

$t->json_is("/$_", $fetched_query_record->{$_}) for keys %{$fetched_query_record};

ok $t->app->routes->find('delete_query_file_query'), 'Route exists';
my $delete_query_file_query_url = $t->app->url_for('delete_query_file_query', query_file_id => $fetched_file->{id}, query_id => $fetched_query_record->{id});
ok ($delete_query_file_query_url, 'Get query file query url exists');

$t->delete_ok($delete_query_file_query_url)
  ->status_is(200);

$t->get_ok($get_query_file_query_url)
  ->status_is(404);

ok $t->app->routes->find('delete_query_file'), 'Route exists';
my $delete_query_file_url = $t->app->url_for('delete_query_file', query_file_id => $fetched_file->{id});
ok ($delete_query_file_url, 'Get query file url exists');

$t->delete_ok($delete_query_file_url)
  ->status_is(200);

$t->get_ok($get_query_file_url)
  ->status_is(404);

# Check if database is empty

ok(test_db()->resultset('QueryFile')->count() == 0, 'No query files');
ok(test_db()->resultset('QueryRecord')->count() == 0, 'No queries');

done_testing();