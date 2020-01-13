use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Test::Deep;
use File::Basename 'dirname';
use Digest::SHA qw(sha1_hex);
use Mojo::IOLoop;

use lib dirname(__FILE__);

require 'bootstrap.pl';

my $t = test_app();
my $tb = test_treebank();
my $tu = test_user();

$t->reset_session();

ok $t->app->routes->find('create_query_file'), 'Route exists';
my $create_query_file_url = $t->app->url_for('create_query_file');
ok ($create_query_file_url, 'Create query file url exists');

my $query_file = {
  name => 'test_file'
};

$t->post_ok($create_query_file_url => json => $query_file)
  ->status_is(401);

login_user($t, {
  auth => {
    username => 'tester',
    password => 'tester'
  }
});

$t->post_ok($create_query_file_url => json => $query_file)
  ->status_is(200);

$t->post_ok($create_query_file_url => json => $query_file)
  ->status_is(400);

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


subtest 'QUERY ORDER' => sub { # query order
  ok $t->app->routes->find('update_list_query_file_queries'), 'Route exists';
  my $set_query_order_url = $t->app->url_for('update_list_query_file_queries', query_file_id => $fetched_file->{id});
  my $i=0;
  my $all_queries_order = [ map {{id => $_->{id}, ord => $i++}} @{$all_queries}];
  $t->put_ok($set_query_order_url => json => {queries => $all_queries_order})
    ->status_is(200);
  $t->get_ok($get_query_file_url)
    ->status_is(200);
  $all_queries = [ sort {$a->{ord} <=> $b->{ord}} @{$t->tx->res->json->{queries}}];
  ok(cmp_deeply([map { get_subhash($_,qw/ord id/) } @$all_queries], $all_queries_order), 'Query order is ok');

  $i=0;
  $all_queries_order = [ map {{id => $_->{id}, ord => $i++}} reverse @{$all_queries}]; # REVERSE ORDER
  $t->put_ok($set_query_order_url => json => {queries => $all_queries_order})
    ->status_is(200);
  $t->get_ok($get_query_file_url)
    ->status_is(200);
  $all_queries = [ sort {$a->{ord} <=> $b->{ord}} @{$t->tx->res->json->{queries}}];
  ok(cmp_deeply([map { get_subhash($_,qw/ord id/) } @$all_queries], $all_queries_order), 'Query reverse order is ok');
};

ok $t->app->routes->find('update_query_file_query'), 'Route exists';
my $update_query_file_query_url = $t->app->url_for('update_query_file_query', query_file_id => $fetched_file->{id}, query_id => $fetched_query_record->{id});
ok ($update_query_file_query_url, 'Get query file query url exists');

$fetched_query_record->{name} = 'A name';
# got {tb_id => tb_name}
$fetched_query_record->{treebanks} = [ keys %{$fetched_query_record->{treebanks}}];
# send [tb_id]
$t->put_ok($update_query_file_query_url => json => $fetched_query_record)
  ->status_is(200);

$t->json_is("/$_", $fetched_query_record->{$_}) for grep {! $_ eq 'treebanks'} keys %{$fetched_query_record};

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

my $auth_sign_out_url = $t->app->url_for('auth_sign_out');
$t->delete_ok($auth_sign_out_url)
  ->status_is(200);

# Check if database is empty

ok(test_db()->resultset('QueryFile')->count() == 0, 'No query files');
ok(test_db()->resultset('QueryRecord')->count() == 0, 'No queries');


subtest 'CHANGE QUERY LIST' => sub { # move query to other list
  my ($test_user) = map {
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
  } ([qw/user1 pass1 name1/]);

  $test_user->{user} = test_user($test_user->{save});
  login_user($t, $test_user->{login}, $test_user->{save}->{name});

  my @query_files = map { {name => $_} } qw/CHQ_file1 CHQ_file2/;
  $t->post_ok($create_query_file_url => json => $_)
    ->status_is(200)
    for (@query_files);
  $t->get_ok($list_query_files_url)
    ->status_is(200);
  ok (@{$t->tx->res->json} == 2, 'Two query files is in the list');
  my %fetched_query_files = map {$_->{name} => $_} @{$t->tx->res->json};
  for $fetched_file (values %fetched_query_files) {
    my $create_query_file_queries_url = $t->app->url_for('create_query_file_query', query_file_id => $fetched_file->{id});
    my $ord=0;
    for (qw/query1 query2 query3/) {
      $t->post_ok($create_query_file_queries_url => json => {
        name => "$fetched_file->{name} $_",
        query => "a-node [ attr = '$fetched_file->{name} $_' ]",
        ord => $ord++
      })->status_is(200);
    }
  }
  $t->get_ok($list_query_files_url)
    ->status_is(200);
  %fetched_query_files = map {$_->{name} => $_} @{$t->tx->res->json};
  $_->{queries} = [ sort {$a->{ord} <=> $b->{ord}} @{$_->{queries}}] for (values %fetched_query_files); # sort queries

  # move query 'CHQ_file1 query2'
  # 'CHQ_file1' = [CHQ_file1 query1' 'CHQ_file1 query3'] # no change
  # 'CHQ_file2' = [CHQ_file2 query1' 'CHQ_file2 query2' 'CHQ_file1 query1' 'CHQ_file2 query3'] # changing order
  my $file1query2 = $fetched_query_files{'CHQ_file1'}->{queries}->[1];
  splice @{$fetched_query_files{'CHQ_file1'}->{queries}}, 1, 1;
  splice @{$fetched_query_files{'CHQ_file2'}->{queries}}, 2, 0, $file1query2;
  
  # change query record's list:
  my $update_query_file_query_url = $t->app->url_for('update_query_file_query', query_file_id => $fetched_query_files{'CHQ_file1'}->{id}, query_id => $file1query2->{id});
  $file1query2->{queryFileId} = $fetched_query_files{'CHQ_file2'}->{id};
  $t->put_ok($update_query_file_query_url => json => $file1query2)
    ->status_is(200);
  
  # update target query list order:
  my $i=0;
  my $order_file2 = [ map {{id => $_->{id}, ord => $i++}} @{$fetched_query_files{'CHQ_file2'}->{queries}}];
  my $set_query_order_url = $t->app->url_for('update_list_query_file_queries', query_file_id => $fetched_query_files{'CHQ_file2'}->{id});
  $t->put_ok($set_query_order_url => json => {queries => $order_file2})
    ->status_is(200);
  
  $t->get_ok($list_query_files_url)
    ->status_is(200);
  %fetched_query_files = map {$_->{name} => $_} @{$t->tx->res->json};
  $_->{queries} = [ sort {$a->{ord} <=> $b->{ord}} @{$_->{queries}}] for (values %fetched_query_files); # sort queries

  ok(cmp_deeply([map { get_subhash($_,qw/ord id/) } @{$fetched_query_files{'CHQ_file2'}->{queries}}], $order_file2), 'Query order file2 is ok');

  logout_user($t, $test_user->{save}->{name});
};


# test that queryFiles are not shared among users

my $tu2_data = {username => 'tu2', password => 'tu2'};
my $tu2 = test_user($tu2_data);
login_user($t, {
  auth => $tu2_data
});

my $query_file2 = {
  name => 'test_file_2'
};
$t->post_ok($create_query_file_url => json => $query_file2)
  ->status_is(200);

$t->get_ok($list_query_files_url)
  ->status_is(200);

$t->json_is("/0/$_", $query_file2->{$_}) for keys %{$query_file2};

is (scalar @{$t->tx->res->json} , 1, 'One query file is in the list');

$t->delete_ok($auth_sign_out_url)
  ->status_is(200);

login_user($t, {
  auth => {
    username => 'tester',
    password => 'tester'
  }
});

$t->get_ok($list_query_files_url)
  ->status_is(200);

is (scalar @{$t->tx->res->json} , 0, 'No query file is in the list');

$t->post_ok($create_query_file_url => json => $query_file2)
  ->status_is(200, 'insert new query file with thw same name');

$t->get_ok($list_query_files_url)
  ->status_is(200);

$t->json_is("/0/$_", $query_file2->{$_}) for keys %{$query_file2};

is (scalar @{$t->tx->res->json} , 1, 'One query file is in the list');
ok (!(grep {$_->{userId} != $tu->id} @{$t->tx->res->json}), 'all query files belongs to current user');

$t->delete_ok($auth_sign_out_url)
  ->status_is(200);

done_testing();


sub get_subhash {
  my %hash = %{shift,};
  my %ret = map {$_ => $hash{$_}} @_;
  return \%ret;
}