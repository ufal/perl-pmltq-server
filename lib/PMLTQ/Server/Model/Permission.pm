package PMLTQ::Server::Model::Permission;

use PMLTQ::Server::Document 'permissions';
use Types::Standard qw(Str);

field [qw/name comment/] => (isa => Str);
