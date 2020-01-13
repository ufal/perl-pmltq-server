use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use File::Basename 'dirname';
use Digest::SHA qw(sha1_hex);
use Mojo::IOLoop;

use lib dirname(__FILE__);

require 'bootstrap.pl';

start_postgres();
my $t = test_app();
my $tb = test_treebank();
my $tb2 = test_treebank({name => 'tb2', title => 'Second treebank'});
my $tu = test_user();

$t->reset_session();

ok $t->app->routes->find('create_query_file'), 'Route exists';
my $create_query_file_url = $t->app->url_for('create_query_file');
ok ($create_query_file_url, 'Create query file url exists');

my $query_file = {
  name => 'test_file'
};

login_user($t, {
  auth => {
    username => 'tester',
    password => 'tester'
  }
});

$t->post_ok($create_query_file_url => json => $query_file)
  ->status_is(200);

ok $t->app->routes->find('list_query_files'), 'Route exists';
my $list_query_files_url = $t->app->url_for('list_query_files');
ok ($list_query_files_url, 'List query files url exists');

$t->get_ok($list_query_files_url)
  ->status_is(200);

my $fetched_file = $t->tx->res->json->[0];

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


$t->get_ok($list_query_files_url)
  ->status_is(200);
  $t->json_is("/0/queries/0/$_", $query_record->{$_}) for keys %{$query_record};

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

my $query_url = $t->app->url_for('query', treebank_id => $tb->id);
ok ($query_url, 'Constructing url for query');

my $history_url = $t->app->url_for('history');
ok ($history_url, 'Has history url');

subtest "Execute query" => sub { # execute query
  $t->post_ok($query_url => json => {
    query => $query_record->{query},
    query_record_id => $fetched_query_record->{id}
  })->status_is(200);

  # test whether both (HISTORY, test_file) query records contain treebank

  $t->get_ok($list_query_files_url => form => {history_list => 1})
    ->status_is(200);
  ## check querylists
  ok (@{$t->tx->res->json} == 2, 'Two query files are in the list');

  $t->json_is("/$_/queries/0/treebanks/".$tb->id, $tb->name) for (0..1);

  ## check HISTORY

  $t->get_ok($history_url)
    ->status_is(200);
  is(scalar @{$t->tx->res->json->[0]->{queries}}, 1, 'History has one record');
  $t->json_is("/0/queries/0/treebanks/".$tb->id, $tb->name);
};

subtest "Evaluate query record on second treebank" => sub { # evaluate query on second treebank

  my $query_url2 = $t->app->url_for('query', treebank_id => $tb2->id);
  ok ($query_url2, 'Constructing url for query on second treebank');

  $t->post_ok($query_url2 => json => {
    query => $query_record->{query},
    query_record_id => $fetched_query_record->{id}
  })->status_is(200);

  ## check query_list
  $t->get_ok($list_query_files_url => form => {history_list => 0}) # get lists without history
    ->status_is(200);
  ## check querylist
  $t->json_is("/0/queries/0/treebanks/".$_->id, $_->name) for ($tb,$tb2);
  ## check history
  $t->get_ok($history_url)
    ->status_is(200);
  is(scalar @{$t->tx->res->json->[0]->{queries}}, 2, 'History has two records');

  $t->json_is("/0/queries/0/treebanks/".$tb->id, $tb->name);
  $t->json_is("/0/queries/1/treebanks/".$tb2->id, $tb2->name);
  is(scalar keys %{$t->tx->res->json->[0]->{queries}->[$_]->{treebanks}}, 1, "Record number $_ has one treebank assigned") for (0..1);
};

subtest "Edit query (fixing evaluated treebank list)" => sub { # edit query
  ok $t->app->routes->find('update_query_file_query'), 'Route exists';
  my $update_query_file_query_url = $t->app->url_for('update_query_file_query', query_file_id => $fetched_file->{id}, query_id => $fetched_query_record->{id});
  ok ($update_query_file_query_url, 'Get query file query url exists');
  ## rename
  $t->put_ok($update_query_file_query_url => json => {name => 'RENAMED', id => $fetched_query_record->{id}})
    ->status_is(200);

  $t->get_ok($list_query_files_url => form => {history_list => 0}) # get lists without history
    ->status_is(200);
  $t->json_is("/0/queries/0/treebanks/".$_->id, $_->name) for ($tb,$tb2);

  ## change query

  $t->put_ok($update_query_file_query_url => json => {query => $fetched_query_record->{id}.' >> count() ## changed query', id => $fetched_query_record->{id}})
    ->status_is(200);

  $t->get_ok($list_query_files_url => form => {history_list => 0}) # get lists without history
    ->status_is(200);
  is(scalar keys %{$t->tx->res->json->[0]->{queries}->[0]->{treebanks}}, 0, "Record has no treebank assigned - was changed and not evaluated");
};

done_testing();
