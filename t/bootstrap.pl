# bootstraping tests
use Mojo::Base -strict;

use Test::More;
use Test::PostgreSQL;
use Test::Mojo;

use File::Basename 'dirname';
use File::Spec;
use File::Which qw( which );

use lib File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..', 'lib'));

my $pgsql = Test::PostgreSQL->new()
    or plan skip_all => $Test::PostgreSQL::errstr;

my $pg_restore = which('pg_restore');
die "Cannot find pg_restore in your path" unless $pg_restore;

my $test_tb;
my $app;

sub test_app {
  return $app if $app;
  $app = Test::Mojo->new('PMLTQ::Server');
  return $app;
}

sub test_treebank {
  return $test_tb if $test_tb;

  my $treebanks = test_app()->app->mandel->collection('treebank');
  $test_tb = $treebanks->create({
    name => 'pdt20_mini',
    title => 'PDT 2.0 Sample',
    driver => 'Pg',
    host => 'localhost',
    port => $pgsql->port,
    database => 'test',
    username => 'postgres',
    password => '',
    public => 1,
    data_sources => [{
      schema => 'adata',
      path => File::Spec->catdir($FindBin::RealBin, 'test_files', 'pdt20_mini', 'data')
    }, {
      schema => 'tdata',
      path => File::Spec->catdir($FindBin::RealBin, 'test_files', 'pdt20_mini', 'data')
    }]
  });

  my $filename = File::Spec->catdir($FindBin::RealBin, 'test_files', 'pdt20_mini', 'pdt20_mini.dump');

  system($pg_restore, '-d', 'test', '-h', 'localhost', '-p', $pgsql->port, '-U', 'postgres', '-no-acl', '--no-owner', '-w', $filename) == 0
    or die "Restoring test database failed: $?";

  return $test_tb
}

1;
