use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use File::Basename 'dirname';
use Data::Dumper;
use Carp::Always;

use lib dirname(__FILE__);

$ENV{PMLTQ_SERVER_TESTDB} = 'mongodb://localhost/pmltq-server-test';
require 'bootstrap.pl';

my $t = test_app();
my $tb = test_treebank();

isa_ok $tb, 'PMLTQ::Server::Model::Treebank';
ok $t->app->routes->find('query'), 'Query route exists';
my $query_url = $t->app->url_for('query', treebank => $tb->name);
ok ($query_url, 'Constructing url');

$t->post_ok($query_url => json => { })
  ->status_is(400)
  ->json_has('/error', 'Got error for empty query');

my $query = 'a-node []';

$t->post_ok($query_url => json => {
  query => $query
})->status_is(200)->or(sub { diag Dumper($t->tx->res->json) })
  ->json_has('/results/0', 'Got some results');

# my $history_url = $t->app->url_for('all_history');
# $t->get_ok($history_url);

done_testing();
