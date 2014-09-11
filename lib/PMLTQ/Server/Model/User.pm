package PMLTQ::Server::Model::User;

# ABSTRACT: Model representing an user

use Mandel::Document 'users';
use Types::Standard qw(Str ArrayRef HashRef);


field [qw/username name pass active  database username/] => ( isa => Str );
#has_many treebanks => PMLTQ::Server::Model::Treebank;
#has_many privs => PMLTQ::Server::Model::Privileges;

field data_source => ( isa => ArrayRef[HashRef[Str]] );



### pouze operace nad jedním uživatelem !!!

sub update {}
sub delete {}
sub privs {}
sub treebanks {}


1;
