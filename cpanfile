requires 'Mojolicious', '6.11';
requires 'DBIx::Class', '0.082820';
requires 'PMLTQ', '0.8.3';

requires 'DateTime', '1.18';
requires 'DateTime::Format::Strptime', '1.56';
requires 'Lingua::EN::Inflect', '1.899';
requires 'Validate::Tiny', '1.551';
requires 'Email::Valid', '1.196';
requires 'Encode', '2.62', '2.73';
requires 'Crypt::Eksblowfish', '0.009';
requires 'Lingua::Translit', '0.21';
requires 'Config::General', '2.57';
requires 'Config::Any', '0.26';
requires 'WWW::Mailgun', '0.4';
requires 'String::CamelSnakeKebab', '0.03';
requires 'DBIx::Class::ResultSet::RecursiveUpdate', '0.34';
requires 'DBIx::Class::Helpers';
requires 'DBIx::Class::EncodedColumn';
requires 'DBIx::Class::FilterColumn::ByType';
requires 'Digest::MD4';

# requires 'Mojolicious::Plugin::ValidateTiny', '0.14'; # Using an internal version for now
# requires 'Mojolicious::Plugin::ParamExpand', '0.02';
requires 'Mojolicious::Plugin::Authentication', '1.26';
# requires 'Mojolicious::Plugin::Authorization', '1.0302';
requires 'Mojolicious::Plugin::HttpBasicAuth', '0.12';

on 'test' => sub {
  requires 'Test::More', '1.001014';
  requires 'Test::PostgreSQL', '1.06';
  requires 'Test::Deep', '0.115';
  requires 'IO::Capture::Stderr';
  requires 'Devel::Cover', '1.18';
  requires 'Test::DBIx::Class';
  requires 'Data::Printer';
  requires 'DBIx::Class::Migration';
};
