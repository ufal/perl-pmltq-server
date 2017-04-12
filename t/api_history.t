use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::URL;
use File::Basename 'dirname';
use File::Spec;

use lib dirname(__FILE__);

require 'bootstrap.pl';

start_postgres();
my $t = test_app();
my $tb = test_treebank();
my $tu = test_user();

my $auth_sign_in_url = $t->app->url_for('auth_sign_in');
ok ($auth_sign_in_url, 'Has auth sign in url');

$t->post_ok($auth_sign_in_url => json => {
  auth => {
    username => 'tester',
    password => 'tester'
  }
})->status_is(200);

my $history_url = $t->app->url_for('history');
ok ($history_url, 'Has history url');

$t->get_ok($history_url)
  ->status_is(200);

is(scalar @{$t->tx->res->json}, 1, "Hisory returns only one query file");
is($t->tx->res->json->[0]->{name},'HISTORY', "Hisory query file has 'HISTORY' name");
is(scalar @{$t->tx->res->json->[0]->{queries}}, 0, "No query is in history");

my $query = 'a-node []';

my $query_url = $t->app->url_for('query', treebank_id => $tb->id);
ok ($query_url, 'Constructing url for query');

$t->post_ok($query_url => json => {
  query => $query
})->status_is(200);

$t->get_ok($history_url)
  ->status_is(200);
is(scalar @{$t->tx->res->json->[0]->{queries}}, 1, "One query is in history");
is($t->tx->res->json->[0]->{queries}->[0]->{query}, $query, "Query is equal");


$t->post_ok($query_url => json => {
  query => 'INVALID QUERY'
})->status_is(400)
  ->json_has('/error', 'Got error for invalid query');

$t->get_ok($history_url)
  ->status_is(200);
is(scalar @{$t->tx->res->json->[0]->{queries}}, 1, "Not saving invalid query");


my $list_query_files_url = $t->app->url_for('list_query_files');
ok ($list_query_files_url, 'List query files url exists');

$t->get_ok($list_query_files_url => form => {history_list => 1})
  ->status_is(200);

is(scalar @{$t->tx->res->json}, 1, "HISTORY is in query files");
is($t->tx->res->json->[0]->{name},'HISTORY', "HISTORY is in query files");


$t->get_ok($list_query_files_url => form => {history_list => 0})
  ->status_is(200);

is(scalar @{$t->tx->res->json}, 0, "HISTORY is not in query files (listing without history)");

done_testing();