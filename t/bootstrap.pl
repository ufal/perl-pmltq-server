# bootstraping tests

use Test::More;
use Test::PostgreSQL;
use Test::Mojo;

use File::Spec;
use FindBin;

my $pgsql = Test::PostgreSQL->new()
    or plan skip_all => $Test::PostgreSQL::errstr;

my $test_tb;
my $app;

sub test_app {
  return $app if $app;

  $app = Test::Mojo->new('PMLTQ::Server');

  my $treebanks = $app->app->mango->db->collection('treebanks');
  $test_tb = $treebank_rs->create({
    name => 'pdt20_sample',
    title => 'PDT 2.0 Sample',
    driver => 'Pg',
    host => 'localhost',
    port => $pgsql->port,
    database => 'test',
    username => 'postgres',
    password => '',
    public => 1,
    data_sources => [{
      schema => 'valency_lexicon',
      path => File::Spec->cardir($FindBin::RealBin, 'test_files', 'pdt20_sample', 'pml_valex')
    }, {
      schema => 'adata',
      path => File::Spec->cardir($FindBin::RealBin, 'test_files', 'pdt20_sample', 'sample')
    }, {
      schema => 'tdata',
      path => File::Spec->cardir($FindBin::RealBin, 'test_files', 'pdt20_sample', 'sample')
    }]
  });

  return $app;
}

sub test_treebank { $test_tb }

sub login {
  ok test_app->app->authenticate('', '', { persistent_token => 'admin' }), 'Login successful';
  ok test_app->app->is_user_authenticated, 'User exists';
  #ok test_app->app->current_user, 'User exists';
}

1;
