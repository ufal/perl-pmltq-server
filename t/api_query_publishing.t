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
my @tu = map {
  {
    login => {
      auth => {
        username => $_->[0],
        password => $_->[1]
      }
    },
    save => {
        username => $_->[0],
        password => $_->[1],
        name => $_->[2]
    },
  }
  } ([qw/user1 pass1 name1/],[qw/user2 pass2 name2/]);

$tu[$_]->{user} = test_user($tu[$_]->{save}) for (0..$#tu);

$t->reset_session();

login_user($t, $tu[0]->{login}, $tu[0]->{save}->{name});


ok $t->app->routes->find('public_query_tree'), 'Route exists';
my $list_public_query_url = $t->app->url_for('public_query_tree');
ok ($list_public_query_url, 'List public query url exists');

$t->get_ok($list_public_query_url)
  ->status_is(200);
is(scalar keys %{$t->tx->res->json},0,"Neither public query nor public list");


my $queryfile1_id = create_queryfile($t, {name => "QF1"},"create private query file");

my $query1pub_id = create_query_in_queryfile($t, {query => 'a-node []', name => "public query", is_public => 1}, $queryfile1_id, "create public query in private query file");
my $query1priv_id = create_query_in_queryfile($t, {query => 'a-root []', name => "private query"}, $queryfile1_id, "create private query in private query file");

logout_user($t, $tu[0]->{save}->{name});

$t->get_ok($list_public_query_url)
  ->status_is(200);
is(scalar keys %{$t->tx->res->json},1,"One user has a public query or list");
$t->json_is("/".$tu[0]->{user}->id."/name", $tu[0]->{save}->{name});
is(scalar @{$t->tx->res->json->{$tu[0]->{user}->id}->{files}},1,"One public query list");
$t->json_has("/".$tu[0]->{user}->id."/files/0/$_") for (qw/id user_id name/);
$t->json_hasnt("/".$tu[0]->{user}->id."/files/0/queries");

ok $t->app->routes->find('public_query_file'), 'Route exists';
my $public_query_file_url_0 = $t->app->url_for('public_query_file', 'user_id' => $tu[0]->{user}->id, 'query_file_id' => 'public'); # url for file with all public labeled queries
ok ($public_query_file_url_0, 'Public query file url exists (user 0)');
my $public_query_file_url_1 = $t->app->url_for('public_query_file', 'user_id' => $tu[1]->{user}->id, 'query_file_id' => 'public'); # url for file with all public labeled queries
ok ($public_query_file_url_1, 'Public query file url exists (user 1)');

$t->get_ok($public_query_file_url_0)
  ->status_is(200);

is(scalar @{$t->tx->res->json->{queries}},1,"User 0 has 1 public query");

$t->get_ok($public_query_file_url_1)
  ->status_is(200);
is(scalar @{$t->tx->res->json->{queries}},0,"User 1 has 0 public query");

my $private_query_file_url_0 = $t->app->url_for('public_query_file', 'user_id' => $tu[0]->{user}->id, 'query_file_id' => $queryfile1_id);
ok ($private_query_file_url_0, 'Private query file url exists (user 0)');
$t->get_ok($private_query_file_url_0)
  ->status_is(404);

login_user($t, $tu[1]->{login}, $tu[1]->{save}->{name});
$t->get_ok($private_query_file_url_0)
  ->status_is(404);

my $queryfile2_id = create_queryfile($t, {name => "QF2", is_public => 1},"create public query file");

my $query_file_url_1 = $t->app->url_for('public_query_file', 'user_id' => $tu[1]->{user}->id, 'query_file_id' => $queryfile2_id);
ok ($query_file_url_1, "Public query file (id=$queryfile2_id) url exists (user 1)");
$t->get_ok($query_file_url_1)
  ->status_is(200);

logout_user($t, $tu[1]->{save}->{name});

$t->get_ok($query_file_url_1)
  ->status_is(200);


login_user($t, $tu[0]->{login}, $tu[0]->{save}->{name});

$t->get_ok($query_file_url_1)
  ->status_is(200);

$t->get_ok($private_query_file_url_0)
  ->status_is(200);





done_testing();