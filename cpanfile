requires 'Mojolicious';
requires 'Mango';
requires 'Mandel';
requires 'PMLTQ', '0.8.0';

requires 'Mojolicious::Plugin::Bootstrap3';
requires 'Mojolicious::Plugin::Authentication';
requires 'Mojolicious::Plugin::Authorization';

on 'test' => sub {
  requires 'Test::More';
  requires 'Test::PostgreSQL'
};
