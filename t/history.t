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
my $user = test_user();

my $query = <<Q;
a-node []
Q

my $hash = sha1_hex($query);
my $c = $t->app->build_controller;

my $key = $c->history_key;
my $key2 = $c->history_key;
is ($key, $key2, 'The history key is persistent');

my $record = $tb->record_history($key, $query);

isa_ok $record, 'PMLTQ::Server::Model::History';
isa_ok $record, 'PMLTQ::Server::Document';

ok ($record->id, 'Has ID');
ok ($record->query, 'Has query');
is ($record->query, $query, 'Query match');
is ($record->query_sum, $hash, 'Hash is ok');

my $rec_from_db = $t->app->mandel
	->collection('history')
	->search({ query_sum => $hash, history_key => $key })
	->single();

# use Data::Dumper;
# say STDERR Dumper($rec_from_db->{data});

ok ($rec_from_db, 'Database returned valid record');
is ($rec_from_db->id, $record->id, 'Id match the one in database');
is ($rec_from_db->history_key, $record->history_key, 'History key match the one in database');
is ($rec_from_db->query, $record->query, 'Query match the one in database');
is ($rec_from_db->query_sum, $record->query_sum, 'Query sum match the on in database');

ok (!$rec_from_db->user, 'Have no user');

my $treebank_obj = $rec_from_db->treebank;
ok ($treebank_obj, 'Record has a treebank');
is ($treebank_obj->id, $tb->id, 'Treebank match');

my $user_obj = $rec_from_db->user;
ok (!$user_obj, 'Record has no user');

$record = $tb->record_history($key, $query, $user);

my $rec_from_db2 = $t->app->mandel
  ->collection('history')
  ->search({ query_sum => $record->query_sum, history_key => $key, 'user.$id' => $user->id })
  ->single();

ok ($rec_from_db2, 'Database returned valid record');
isnt ($rec_from_db, $rec_from_db2, 'Different record for the user');

$user_obj = $rec_from_db2->user;
ok ($user_obj, 'Record has a user');
is ($user_obj->id, $user->id, 'User match');

# test history

my $history_url = $t->app->url_for('treebank_history', treebank => $tb->name);
ok ($history_url, 'Constructing url for history');

$t->app->defaults->{'mojo.session'} = {history_key => $key};
$t->get_ok($history_url)
  ->status_is(200);

my $arr = $t->tx->res->json;
ok (@$arr == 2, 'Array has two elements');
$t->json_has('/0/_id')->json_has('/1/_id')->json_is('/0/history_key', $key);

done_testing();
