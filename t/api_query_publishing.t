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


# no public query
ok $t->app->routes->find('public_query_tree'), 'Route exists';
my $list_public_query_url = $t->app->url_for('public_query_tree');
ok ($list_public_query_url, 'List public query url exists');

$t->get_ok($list_public_query_url)
  ->status_is(200);
is(scalar @{$t->tx->res->json},0,"Neither public query nor public list");

# create public and private query in private list
login_user($t, $tu[0]->{login}, $tu[0]->{save}->{name}); ## LOGIN 0 ###################

my $queryfile_0priv_id = create_queryfile($t, {name => "QF1"},"create private query file");

my $query_00pub_id = create_query_in_queryfile($t, {query => 'a-node []', name => "0 public query", is_public => 1}, $queryfile_0priv_id, "create public query in private query file");
my $query_01priv_id = create_query_in_queryfile($t, {query => 'a-root []', name => "0 private query"}, $queryfile_0priv_id, "create private query in private query file");

my $queryfile_0priv_url = $t->app->url_for('public_query_file', 'user_id' => $tu[0]->{user}->id)->query(file => $queryfile_0priv_id);
ok ($queryfile_0priv_url, 'Private query file url exists (user 0)');

$t->get_ok($queryfile_0priv_url)
  ->status_is(200);

logout_user($t, $tu[0]->{save}->{name});  ## LOGOUT 0 ###################

# check public query and fake querylist "PUBLIC" 
$t->get_ok($list_public_query_url)
  ->status_is(200);
is(scalar @{$t->tx->res->json},1,"One user has a public query or list");
$t->json_is("/0/$_", $tu[0]->{user}->$_) for qw/name id/;
is(scalar @{$t->tx->res->json->[0]->{files}},1,"One public query list");
$t->json_has("/0/files/0/$_") for (qw/id user_id name/);
$t->json_hasnt("/0/files/0/queries");

ok $t->app->routes->find('public_query_file'), 'Route exists';
my $queryfile_usr0pub_url = $t->app->url_for('public_query_file', 'user_id' => $tu[0]->{user}->id)->query(file => 'public'); # url for file with all public labeled queries
ok ($queryfile_usr0pub_url, 'Public query file url exists (user 0)');
my $queryfile_usr1pub_url = $t->app->url_for('public_query_file', 'user_id' => $tu[1]->{user}->id)->query(file => 'public'); # url for file with all public labeled queries
ok ($queryfile_usr1pub_url, 'Public query file url exists (user 1)');

$t->get_ok($queryfile_usr0pub_url)
  ->status_is(200);

is(scalar @{$t->tx->res->json->{queries}},1,"User 0 has 1 public query");

$t->get_ok($queryfile_usr1pub_url)
  ->status_is(200);
is(scalar @{$t->tx->res->json->{queries}},0,"User 1 has 0 public query");

# private query list is not accessible for OTHER user
login_user($t, $tu[1]->{login}, $tu[1]->{save}->{name}); ## LOGIN 1 ###################
$t->get_ok($queryfile_0priv_url)
  ->status_is(404);

# create public querylist for second user
my $queryfile_1pub_id = create_queryfile($t, {name => "QF2", is_public => 1},"create public query file");

my $queryfile_1pub_url = $t->app->url_for('public_query_file', 'user_id' => $tu[1]->{user}->id)->query(file => $queryfile_1pub_id);
ok ($queryfile_1pub_url, "Public query file (id=$queryfile_1pub_id) url exists (user 1)");
$t->get_ok($queryfile_1pub_url)
  ->status_is(200);

my $query2pub_id = create_query_in_queryfile($t, {query => 'a-node []', name => "1 public query", is_public => 1}, $queryfile_1pub_id, "create public query in public query file");
my $query2priv_id = create_query_in_queryfile($t, {query => 'a-root []', name => "1 private query"}, $queryfile_1pub_id, "create private query in public query file");

logout_user($t, $tu[1]->{save}->{name}); ## LOGOUT 1 ###################



$t->get_ok($queryfile_0priv_url) # USER 0 PRIVATE FILE
  ->status_is(404);

$t->get_ok($queryfile_1pub_url) # USER 1 PUBLIC FILE
  ->status_is(200);

$t->get_ok($list_public_query_url)
  ->status_is(200);
is(scalar @{$t->tx->res->json},2,"Two users has a public query or list");










done_testing();