# bootstraping tests
use Mojo::Base -strict;
use File::Basename 'dirname';
use File::Spec;

use Test::More;
use lib File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..', '..', 'Test-postgresql', 'lib'));
use Test::PostgreSQL;
use Test::Mojo;
use DBI;

use Treex::PML;
use File::Which qw( which );

use lib File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..', 'lib'));

$ENV{MOJO_MODE} = 'test';

unless ($ENV{PMLTQ_SERVER_TESTDB}) {
  #$mongo_database = "pmltq-server-test-$$";
  my $mongo_database = "pmltq-server-test";
  $ENV{PMLTQ_SERVER_TESTDB} = "mongodb://localhost/$mongo_database";
  # $mongo_shell = $ENV{MONGO_SHELL} || which('mongo');

  # plan skip_all => "Skipping tests because there is no Mongodb installed";
}

my $test_files = File::Spec->catdir(dirname(__FILE__), 'test_files');
my $pg_dir = File::Spec->catdir(dirname(__FILE__), 'postgres');
my $pg_expect_running = -d $pg_dir;
my $pg_port = $ENV{PG_PORT} || 11543;
my ($pg_running, $pg_restore, $pgsql);

my $test_dsn = "DBI:Pg:dbname=test;host=127.0.0.1;port=$pg_port;user=postgres";

if ($pg_expect_running && !$ENV{PG_LOCAL}) {
  my $dbh = DBI->connect($test_dsn, undef, undef, { PrintError => 0, RaiseError => 0 });
  $pg_running = $dbh->ping if $dbh;
  diag 'Connection to local postgres failed' unless $pg_running;
  undef $dbh;
}

unless ($pg_running) {
  $pgsql = Test::PostgreSQL->new(
    port => $pg_port,
    auto_start => 0,
    ($ENV{PG_LOCAL} ? (base_dir => $pg_dir) : ()), # use dir for subsequent runs to simply skip initialization
  ) or plan skip_all => $Test::PostgreSQL::errstr;

  $pgsql->setup() unless (-d $pgsql->base_dir);  # create postgress dir does not exists

  $pgsql->start;
    
  $pg_port = $pgsql->port;  
  $pg_restore = $ENV{PG_RESTORE} || which('pg_restore');
  die "Cannot find pg_restore in your path and is not provided in PG_RESTORE variable either" unless $pg_restore;
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
  return if $pg_expect_running; 

  my $filename = File::Spec->catdir($test_files, 'pdt20_mini', 'pdt20_mini.dump');

  my @cmd = ($pg_restore, '-d', 'test', '-h', 'localhost', '-p', $pg_port, '-U', 'postgres', '--no-acl', '--no-owner', '-w', $filename);
  say STDERR join(' ', @cmd);
  system(@cmd) == 0 or die "Restoring test database failed: $?";
}

sub run_database {
  return unless $pgsql;
  say STDERR "Connect to: " . $pgsql->dsn;
  say STDERR "Press CTR-C to terminate...";
  sleep;
}

END {
  test_app()->app->db->db->collection_names(sub {
    my ($db, $err, $names) = @_;
    unless ($err) {
      $db->collection($_)->drop for (@$names);
    }
  });
}

1;
