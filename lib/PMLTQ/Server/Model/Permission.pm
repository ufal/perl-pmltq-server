package PMLTQ::Server::Model::Permission;

use PMLTQ::Server::Document 'permissions';
use Types::Standard qw(Str);
use Exporter 'import';

BEGIN {
  use constant {
    map { ( uc $_ => $_ ) } qw/admin all_treebanks shibboleth/
  };

  our @EXPORT = map { uc } qw/admin all_treebanks shibboleth/;
  our %EXPORT_TAGS = (
    constants => [ @EXPORT ],
  );
}

field [qw/name comment/] => (isa => Str);
