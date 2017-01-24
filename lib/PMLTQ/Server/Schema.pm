package PMLTQ::Server::Schema;

use Mojo::Base qw/DBIx::Class::Schema/;

our $VERSION = 3;

__PACKAGE__->load_components(qw/
  Helper::Row::NumifyGet
/);

__PACKAGE__->load_namespaces(default_resultset_class => '+DBIx::Class::ResultSet::RecursiveUpdate');

1;
