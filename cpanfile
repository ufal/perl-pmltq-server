requires 'Mojolicious';
requires 'Mango';
requires 'Mandel', '0.23';
requires 'PMLTQ', '0.8.2';

requires 'Lingua::EN::Inflect', '1.895';

requires 'Mojolicious::Plugin::Authentication';
requires 'Mojolicious::Plugin::Authorization';

on 'test' => sub {
  requires 'Test::More';
  requires 'Test::PostgreSQL'
};
