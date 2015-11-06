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

isa_ok $tb, 'PMLTQ::Server::Schema::Result::Treebank';
ok $t->app->routes->find('query'), 'Query route exists';
my $query_url = $t->app->url_for('query', treebank_id => $tb->id);
ok ($query_url, 'Constructing url for query');

$t->post_ok($query_url => json => { })
  ->status_is(400)
  ->json_has('/error', 'Got error for empty query');

my $query = 'a-node []';

$t->post_ok($query_url => json => {
  query => $query
})->status_is(200)->or(sub { diag p($t->tx->res->json) })
  ->json_has('/results/0', 'Got some results');

# Check history
# $session = extract_session($t);
# ok ($session, 'Got session');
# ok ($session->{history_key}, 'Got history key');

# my $history_url = $t->app->url_for('treebank_history', treebank_id => $tb->id);
# ok ($history_url, 'Constructing url for history');
# $t->get_ok($history_url)
#   ->status_is(200);

# my $arr = $t->tx->res->json;
# ok (@$arr == 1, 'One item in the history');
# $t->json_has('/0/_id')
#   ->json_is('/0/history_key', $session->{history_key})
#   ->json_is('/0/query', $query)
#   ->json_has('/0/query_sum')
#   ->json_has('/0/last_use');

my $print_server_url = Mojo::URL->new(start_print_server());

$t->app->config->{tree_print_service} = $print_server_url->path('/svg')->to_string;

#diag $t->app->config->{tree_print_service};

ok $t->app->routes->find('result_svg'), 'Route exists';
my $svg_url = $t->app->url_for('result_svg', treebank_id => $tb->id);
ok ($svg_url, 'Constructing url for printing svg');
$t->post_ok($svg_url => json => {
  nodes => ['109/a-node@a-ln94210-39-p2s1Bw5']
})->status_is(200)->or(sub { diag p($t->tx->res->json) })
  ->header_is('Content-Type' => 'image/svg+xml');

ok $t->app->routes->find('query_svg'), 'Route exists';
my $query_svg_url = $t->app->url_for('query_svg', treebank_id => $tb->id);
ok ($query_svg_url, 'Constructing url for printing svg query');

$t->post_ok($query_svg_url => json => {
  query => $query
})->status_is(200)->or(sub { diag p($t->tx->res->json) })
  ->content_type_is('image/svg+xml');

# switch to failing print server
$t->app->config->{tree_print_service} = $print_server_url->path('/svg_error')->to_string;

$t->post_ok($svg_url => json => {
  nodes => ['109/a-node@a-ln94210-39-p2s1Bw5']
})->status_is(500);

$t->post_ok($query_svg_url => json => {
  query => $query
})->status_is(500);

done_testing();
