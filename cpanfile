requires 'Mojolicious';
requires 'Mango';
requires 'Mandel', '0.23';
requires 'PMLTQ', '0.8.3';

requires 'DateTime', '1.12';
requires 'DateTime::Format::Strptime';
requires 'Lingua::EN::Inflect', '1.895';
requires 'Validate::Tiny', '0.984';
requires 'Email::Valid', '1.195';
requires 'Encode', '2.62';
requires 'Crypt::Eksblowfish', '0.009';
requires 'Lingua::Translit', '0.21';

requires 'Mojolicious::Plugin::ValidateTiny', '0.13';
requires 'Mojolicious::Plugin::ParamExpand';
requires 'Mojolicious::Plugin::Authentication';
requires 'Mojolicious::Plugin::Authorization';
requires 'Mojolicious::Plugin::Mail';
requires 'Mojolicious::Plugin::HttpBasicAuth', '0.11';

on 'test' => sub {
  requires 'Test::More';
  requires 'Test::PostgreSQL';
  requires 'Test::Deep';
  requires 'HTML::Lint::Pluggable', '0.03';
  requires 'Test::WWW::Mechanize::Mojo'
};
