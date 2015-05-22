use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use File::Basename 'dirname';
use File::Spec;
use Mojo::JSON;
use Data::Dump;

use lib dirname(__FILE__);

require 'bootstrap.pl';

start_postgres();
my $t = test_app();
my $tb = test_treebank();

my $data_dir = File::Spec->catdir(dirname(__FILE__), 'test_files', 'pdt20_mini', 'data');
$t->app->config->{data_dir} = $data_dir;

my $print_server_url = Mojo::URL->new(start_print_server());
$t->app->config->{nodes_to_query_service} = $print_server_url->path('/pmltq')->to_string;

my @node_ids = qw{2/a-node@a-ln94210-2-p1s1w1 3/a-node@a-ln94210-2-p1s1w2 4/a-node@a-ln94210-2-p1s1w3};
my @invalid_ids = qw{a-node@a-ln94210-2-p1s1w1 a-ln94210-2-p1s1w1 foobar 123};

# Test routes
ok $t->app->routes->find('suggest'), 'Suggest route exists';
my $suggest_url = $t->app->url_for('suggest', treebank_id => $tb->id);
ok ($suggest_url , 'Suggest url');

$t->post_ok($suggest_url)
  ->status_is(400, 'Empty params');

$t->post_ok($suggest_url => json => {ids => []})
  ->status_is(400, 'Empty array as params');

for my $invalid_id (@invalid_ids) {
  $t->post_ok($suggest_url => json => {ids => [$invalid_id]})
    ->status_is(400, "Invalid id: $invalid_id");
}

$t->post_ok($suggest_url => json => { ids => [$node_ids[0]] })
  ->status_is(200)
  ->json_is('/query' => "a-node \$a := [\n  token = 'abc'\n]\n", 'returned query');

$t->post_ok($suggest_url => json => { ids => [@node_ids] })
  ->status_is(200)
  ->json_is('/query' => "a-node \$a := [\n  token = 'abc'\n]\n", 'returned query');

done_testing();
