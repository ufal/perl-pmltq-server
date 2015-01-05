# bootstraping tests
use Mojo::Base -strict;
use File::Basename 'dirname';
use File::Spec;

use Test::More;
use Test::PostgreSQL;
use Test::Mojo;
use Mojo::Util qw(b64_decode hmac_sha1_sum);
use Mojo::JSON;
use Mojo::URL;
use Mojo::IOLoop::Server;
use Mango::BSON qw/bson_oid bson_dbref/;
use DBI;
use DateTime;
use IO::Capture::Stderr;


use Treex::PML;
use File::Which qw( which );
use File::Temp qw(tempfile);
use POSIX qw(WNOHANG);

use lib File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..', 'lib'));

my $loglevel = '';
$ENV{MOJO_MODE} = 'test';
$ENV{MOJO_MAIL_TEST} = 1;
my $mongo_database = "pmltq-server-test-$$";
unless ($ENV{PMLTQ_SERVER_TESTDB}) {
  $ENV{PMLTQ_SERVER_TESTDB} = "mongodb://localhost/$mongo_database";
} else {
  $ENV{PMLTQ_SERVER_TESTDB} = Mojo::URL->new($ENV{PMLTQ_SERVER_TESTDB})->path("/$mongo_database")->to_string;
}

#test_app()->app->db->db->command(dropDatabase => 1);

my $test_files = File::Spec->catdir(dirname(__FILE__), 'test_files');
my $pg_dir = File::Spec->catdir(dirname(__FILE__), 'postgres');
my $pg_expect_running = -d $pg_dir;
my ($pg_running, $pg_restore, $pgsql, $pg_port);

sub start_postgres {
  $pg_port = $ENV{PG_PORT} || Mojo::IOLoop::Server->generate_port;

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

    my $need_init = 0;

    # create postgress dir does not exists
    unless (-d File::Spec->catdir($pgsql->base_dir, 'data')) {
      $pgsql->setup();
      $need_init = 1;
    }

    $pgsql->start;

    $pg_port = $pgsql->port;

    if ($need_init) {
      $pg_restore = $ENV{PG_RESTORE} || which('pg_restore');
      die "Cannot find pg_restore in your path and is not provided in PG_RESTORE variable either" unless $pg_restore;
      init_database();
    }
  }
}

Treex::PML::AddResourcePathAsFirst(File::Spec->catdir($test_files, 'resources'));


sub setup_log {
  $loglevel = shift;
  return IO::Capture::Stderr->new();
}

sub start_log {
  $ENV{MOJO_LOG_LEVEL} = $loglevel;
  shift->start();
}

sub stop_log {
  shift->stop();
  delete $ENV{MOJO_LOG_LEVEL}
}

sub get_log {
  my @lines = shift->read;
  return \@lines;
}

my ($app, $test_tb, $test_user, $admin_user, $encrypt);

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
    anonaccess => 1,
    data_sources => {
      adata => File::Spec->catdir('pdt20_mini', 'data'),
      tdata => File::Spec->catdir('pdt20_mini', 'data')
    }
  });

  $test_tb->save();

  return $test_tb
}

sub test_user {
  return $test_user if $test_user;

  my $users = test_app()->app->mandel->collection('user');
  $test_user = $users->create({
    name => 'Joe Tester',
    username => 'tester',
    password => encrypt_password('tester'),
    email => 'joe@happytesting.com',
  });

  $test_user->save();

  return $test_user
}

sub encrypt_password {
  my $password = shift;
  require PMLTQ::Server::Validation;
  ($encrypt ||= PMLTQ::Server::Validation::encrypt_password());
  return $encrypt->($password);
}

sub test_admin {
  return $admin_user if $admin_user;

  my $users = test_app()->app->mandel->collection('user');
  $admin_user = $users->search({username => 'admin'})->single;

  die 'No admin, hey?' unless $admin_user;
  return $admin_user;
}

sub add_stickers {
  my @stickers = @_ ; # parent sticker should be before children in the list
  my @added;
  my $collection = test_app()->app->mandel->collection('sticker');
  for my $sticker (@stickers){
    my ($name,$comment,$parentIdx) = @$sticker;
    my $parent = undef;
    $parent = $collection->search({name => $stickers[$parentIdx]->[0]})->single if defined $parentIdx;
    my $s = $collection->create({
      name => $name,
      comment => $comment,
      $parent ? (parent => bson_dbref( 'stickers', bson_oid($parent->id) )):()
      });
    $s->save();
    push @added,$s;
  }

  return [@added]
}

my $print_server_pid;

sub start_print_server {
  my $print_server = File::Spec->catfile(dirname(__FILE__), 'script', 'print_server.pl');
  # my $print_server_app = Mojo::Server->new->load_app($print_server);
  # $print_server_app = Test::Mojo->new->app($print_server_app);
  # return $print_server_app->ua->server->nb_url;
  my $port = Mojo::IOLoop::Server->generate_port;
  my $listen = "http://localhost:$port";
  chmod 0755, $print_server;

  say 'Starting print server';

  my ($fh, $filename) = tempfile();

  $print_server_pid = fork;
  die "fork(2) failed:$!" unless defined $print_server_pid;
  if ($print_server_pid == 0) {
    close $fh; open $fh, '>', $filename or die "failed to open log file: $!";
    open STDOUT, '>>&', $fh
      or die "dup(2) failed:$!";
    open STDERR, '>>&', $fh
      or die "dup(2) failed:$!";
    exec("$print_server $port");
    die 'Starting print server failed';
  }

  close $fh;
  # wait until server becomes ready (or dies)
  for (my $i = 0; $i < 100; $i++) {
      open $fh, '<', $filename or die "failed to open log file: $!";
      my $lines = do { join '', <$fh> };
      close $fh;
      last if $lines =~ m{Server is running};
      if (waitpid($print_server_pid, WNOHANG) > 0) {
          # failed
          die $lines;
      }
      sleep 1;
  }

  say "Started listening at: $listen with PID: $print_server_pid";

  return $listen;
}

sub init_database {
  return if $pg_expect_running;

  my $filename = File::Spec->catdir($test_files, 'pdt20_mini', 'pdt20_mini.dump');

  my @cmd = ($pg_restore, '-d', 'test', '-h', 'localhost', '-p', $pg_port, '-U', 'postgres', '--no-acl', '--no-owner', '-w', $filename);
  #say STDERR join(' ', @cmd);
  system(@cmd) == 0 or die "Restoring test database failed: $?";
}

sub run_database {
  return unless $pgsql;
  say STDERR "Connect to: " . $pgsql->dsn;
  say STDERR "Press CTR-C to terminate...";
  sleep;
}

sub extract_session {
    my $t = shift;

    my $jar = $t->ua->cookie_jar;
    my $app = $t->app;
    my $session_name = $app->sessions->cookie_name;

    my ($session_cookie) = grep { $_->name eq $session_name } $jar->all;
    return unless $session_cookie;

    (my $value = $session_cookie->value) =~ s/--([^\-]+)$//;
    my $sign = $1;

    my $ok;
    $sign eq hmac_sha1_sum($value, $_) and $ok = 1 for @{$app->secrets};
    return unless $ok;

    my $session = Mojo::JSON::decode_json(b64_decode $value);
    return $session;
}

END {
  test_app()->app->db->db->command(dropDatabase => 1);

  if ($print_server_pid && $print_server_pid != 0) {
    kill TERM => $print_server_pid;
    # wait for kill TERM to take effect
    select undef, undef, undef, 0.01;
    my $reaped = waitpid $print_server_pid => WNOHANG;
    unless ($reaped == $print_server_pid) {
        say STDERR "Killing print server PID: $print_server_pid by force";
        kill 9 => $print_server_pid;
    }
  }
}

1;
