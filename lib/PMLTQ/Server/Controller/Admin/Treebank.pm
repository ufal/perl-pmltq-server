package PMLTQ::Server::Controller::Admin::Treebank;

# ABSTRACT: Handling everything related to treebanks

use Mojo::Base 'PMLTQ::Server::Controller::CRUD';
use PMLTQ::Server::Validation;

has resultset_name => 'Treebank';

has search_fields => sub { [qw/name title/] };

sub _validate {
  my ($c, $treebank_data) = @_;

  my $rules = {
    fields => [qw/id server_id database name title homepage handle is_public is_free is_all_logged is_featured
                  description data_sources manuals languages tags treebank_provider_ids
                  documentation/],
    filters => [
      # Remove spaces from all
      [qw/name title database homepage description/] => filter(qw/trim/),
      [qw/is_public is_free is_all_logged is_featured/] => force_bool(),
    ],
    checks => [
      [qw/name database/] => is_long_at_most(120),
      [qw/title homepage handle/] => is_long_at_most(120),
      [qw/name title database data_sources server_id/] => is_required(),
      name => is_unique($c->resultset, 'id', 'treebank name already exists'),
      data_sources => is_array_of_hash("invalid data_sources format"),
      manuals => is_array_of_hash("invalid documentation format"),
      treebank_provider_ids => [is_hash("invalid provider IDs format"),is_provider_ids($c->config->{login_with})],
      languages => is_array("invalid documentation format"),
      tags => is_array("invalid documentation format")
    ],
    postprocess => [
      treebank_provider_ids => to_array_of_hash_key_value('provider','provider_id')
    ]
  };
  return $c->do_validation($rules, $treebank_data);
}

1;
