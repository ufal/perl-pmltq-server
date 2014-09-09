use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::URL;
use File::Basename 'dirname';
use File::Spec;
use Data::Dumper;

use lib dirname(__FILE__);

require 'bootstrap.pl';

start_postgres();
my $t = test_app();
my $tb = test_treebank();

isa_ok $tb, 'PMLTQ::Server::Model::Treebank';
ok $t->app->routes->find('query'), 'Query route exists';
my $query_url = $t->app->url_for('query', treebank => $tb->name);
ok ($query_url, 'Constructing url for query');

$t->post_ok($query_url => json => { })
  ->status_is(400)
  ->json_has('/error', 'Got error for empty query');

my $query = 'a-node []';

$t->post_ok($query_url => json => {
  query => $query
})->status_is(200)->or(sub { diag Dumper($t->tx->res->json) })
  ->json_has('/results/0', 'Got some results');

my $print_server_url = Mojo::URL->new(start_print_server());

$t->app->config->{tree_print_service} = $print_server_url->path('/svg')->to_string;

diag $t->app->config->{tree_print_service};

my $svg_url = $t->app->url_for('svg', treebank => $tb->name);
ok ($svg_url, 'Constructing url for printing svg');
$t->post_ok($svg_url => json => {
  nodes => ['109/a-node@a-ln94210-39-p2s1Bw5']
})->status_is(200)->or(sub { diag Dumper($t->tx->res->json) })
  ->header_is('Content-Type' => 'image/svg+xml');

my $query_svg_url = $t->app->url_for('query_svg', treebank => $tb->name);
ok ($query_svg_url, 'Constructing url for printing svg query');

$t->post_ok($query_svg_url => json => {
  query => $query
})->status_is(200)->or(sub { diag Dumper($t->tx->res->json) })
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