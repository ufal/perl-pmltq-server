package PMLTQ::Server::Model::History;

use Mandel::Document (
  name => 'PMLTQ::Server::Document',
  collection_name => 'histories'
);

use Types::Standard qw(Str Ref);
use Digest::SHA qw(sha1_hex);
use DateTime;

belongs_to treebank => 'PMLTQ::Server::Model::Treebank';

belongs_to user => 'PMLTQ::Server::Model::User';

field history_key => (isa => Str);

field query => (isa => Str);

field query_sum => (isa => Str, builder => sub { sha1_hex(shift->query) });

field last_use => (isa => Ref['DateTime'], builder => sub { DateTime->now });

1;
