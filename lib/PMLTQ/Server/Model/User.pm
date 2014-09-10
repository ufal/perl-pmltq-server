package PMLTQ::Server::Model::User;

# ABSTRACT: Model representing an user

use PMLTQ::Server::Document 'users';

use Types::Standard qw(Str ArrayRef Bool HashRef);

has_many histories => 'PMLTQ::Server::Model::History';

field [qw/name username password email/] => (isa => Str);

field [qw/is_active/] => (isa => Bool);

list_of available_treebanks => 'PMLTQ::Server::Model::Treebank';

list_of permissions => 'PMLTQ::Server::Model::Permission';

1;
