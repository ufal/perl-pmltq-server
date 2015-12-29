package PMLTQ::Server::Controller::Admin::Language;

# ABSTRACT: Managing languages in administration

use Mojo::Base 'PMLTQ::Server::Controller::CRUD';

has resultset_name => 'Language';

has search_fields => sub { [qw/name code/] };

sub _validate {
  my ($c, $language_data) = @_;

  my $rules = {
    fields => [qw/id language_group_id code name/],
    filters => [
      # Remove spaces from all
      [qw/name code/] => filter(qw/trim/),
    ],
    checks => [
      [qw/name language_group_id code/] => is_required(),
      name => is_long_at_most(120),
      code => [is_long_at_most(10), is_unique($c->resultset, 'id', 'language code already exists')],
    ]
  };
  return $c->do_validation($rules, $language_data);
}

1;
