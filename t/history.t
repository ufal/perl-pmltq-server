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

my $record = $tb->record_history($query, $user);

isa_ok $record, 'PMLTQ::Server::Model::History';
isa_ok $record, 'PMLTQ::Server::Document';

ok ($record->id, 'Has ID');
ok ($record->query, 'Has query');
is ($record->query, $query, 'Query match');
is ($record->query_sum, $hash, 'Hash is ok');

my $rec_from_db = $t->app->mandel
	->collection('history')
	->search({ query_sum => $hash })
	->single();

# use Data::Dumper;
# say STDERR Dumper($rec_from_db->{data});

ok ($rec_from_db, 'Database returned valid record');
is ($rec_from_db->id, $record->id, 'Id match the one in database');
is ($rec_from_db->query, $record->query, 'Query match the one in database');
is ($rec_from_db->query_sum, $record->query_sum, 'Query sum match the on in database');

my $user_obj = $rec_from_db->user;
ok ($user_obj, 'Record has a user');
is ($user_obj->id, $user->id, 'User match');

my $treebank_obj = $rec_from_db->treebank;
ok ($treebank_obj, 'Record has a treebank');
is ($treebank_obj->id, $tb->id, 'Treebank match');

done_testing();
