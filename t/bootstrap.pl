# bootstraping tests
use Mojo::Base -strict;
use Carp::Always;
use File::Basename 'dirname';
use File::Spec;

use Test::More;
use lib File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..', '..', 'Test-postgresql', 'lib'));
use Test::PostgreSQL;
use Test::Mojo;

use Treex::PML;
use File::Which qw( which );

use lib File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..', 'lib'));
use lib File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..', '..', 'perl-pmltq', 'lib'));

my $test_files = File::Spec->catdir(dirname(__FILE__), 'test_files');
my $pg_dir = File::Spec->catdir(dirname(__FILE__), 'postgres');
my $pg_local = -d $pg_dir && $ENV{LOCAL_PG};
my $pg_port = $ENV{PG_PORT};
my ($pg_restore, $pgsql);

unless ($pg_port) {
  $pgsql = Test::PostgreSQL->new(
    auto_start => 0,
    ($ENV{LOCAL_PG} ? (base_dir => $pg_dir) : ()), # use dir for subsequent runs to simply skip initialization
  ) or plan skip_all => $Test::PostgreSQL::errstr;

  $pgsql->setup() unless (-d $pg_dir);  # create postgress dir does not exists

  $pgsql->start;
    
  $pg_port = $pgsql->port;  
  $pg_restore = which('pg_restore');
  die "Cannot find pg_restore in your path" unless $pg_restore;
}

Treex::PML::AddResourcePathAsFirst(File::Spec->catdir($test_files, 'resources'));

my ($app, $test_tb);

sub test_app {
  return $app ||= Test::Mojo->new('PMLTQ::Server');
}

sub test_treebank {
  return $test_tb if $test_tb;

  my $treebanks = test_app()->app->mandel->collection('treebank');
  $test_tb = $treebanks->create({
    name => 'pdt20_mini',
    title => 'PDT 2.0 Sample',
    driver => 'Pg',
    host => 'localhost',
    port => $pg_port,
    database => 'test',
    username => 'postgres',
    password => '',
    public => 1,
    data_sources => [{
      schema => 'adata',
      path => File::Spec->catdir($test_files, 'pdt20_mini', 'data')
    }, {
      schema => 'tdata',
      path => File::Spec->catdir($test_files, 'pdt20_mini', 'data')
    }]
  });

  $test_tb->save();

  init_database();

  return $test_tb
}

sub init_database {
  return if $pg_local; 

  my $filename = File::Spec->catdir($test_files, 'pdt20_mini', 'pdt20_mini.dump');

  my @cmd = ($pg_restore, '-d', 'test', '-h', 'localhost', '-p', $pg_port, '-U', 'postgres', '--no-acl', '--no-owner', '-w', $filename);
  say STDERR join(' ', @cmd);
  system(@cmd) == 0 or die "Restoring test database failed: $?";
}

sub run_database {
  return unless $pgsql;
  say STDERR "Connect to: " . $pgsql->dsn;
  sleep;
}

1;
