package PMLTQ::Server::Controller::Admin::Server;

# ABSTRACT: Managing tags in administration

use Mojo::Base 'PMLTQ::Server::Controller::CRUD';
use PMLTQ::Server::Validation;

has resultset_name => 'Server';

sub _validate {
  my ($c, $server_data) = @_;

  my $rules = {
    fields => [qw/id name host port username password/],
    filters => [
      [qw/name/] => filter(qw/trim strip/),
    ],
    checks => [
      [qw/name host username password/] => is_long_at_most(120),
      [qw/name host port/] => is_required(),
      name => is_unique($c->resultset, 'id', 'server name already exists'),
      port => is_valid_port_number(),
    ]
  };

  return $c->do_validation($rules, $server_data);
}


1;
