use Rex::Commands;
use Rex::Commands::Run;
use Rex::Commands::Fs;
use Rex::Commands::Upload;

use File::HomeDir;
my $home = File::HomeDir->my_home;

user 'pmltq';
public_key "$home/.ssh/id_rsa.pub";
private_key "$home/.ssh/id_rsa";
key_auth;

group all => 'euler-dev';

my $deploy_to = '/opt/pmltq-server';
my $keep_last = 5;

my $date = run 'date -u +%Y%m%d%H%M%S';
my $deploy_package = "$date.zip";

task 'deploy', group => 'all', sub {

  unless(is_writeable($deploy_to)) {
    Rex::Logger::info("No write permission to $deploy_to");
    exit 1;
  }

  upload ($deploy_package, "/tmp/$deploy_package");

  my $deploy_dir = "$deploy_to/releases/$date";
  unless (is_dir($deploy_dir)) {
    Rex::Logger::debug("rmdir $deploy_dir");
    rmdir $deploy_dir;
  }
  mkdir $deploy_dir;
  run "cd $deploy_dir; unzip /tmp/$deploy_package";
  run "ln -snf $deploy_dir $deploy_to/current";

  unlink "/tmp/$deploy_package";

  my $shared_dir = "$deploy_to/shared";
  unless (is_dir($shared_dir)) {
    mkdir $shared_dir;
  }

  my $config_file = "$shared_dir/pmltq_server.private.conf";
  unless (is_file($config_file)) {
    cp ("$deploy_dir/config/pmltq_server.private.conf.example", $config_file);
  }
  run "ln -snf $config_file $deploy_to/current/config/pmltq_server.private.conf";

  run "ubic restart pmltq";

  # Server cleanup
  my @releases = reverse sort glob("$deploy_to/releases/*");
  while (@releases > $keep_last) {
    my $release = pop @releases;
    Rex::Logger::info("Removing release $release...");
    rmdir $release;
  }
};

before_task_start 'deploy', sub {
  # Build
  LOCAL {
    run "git archive -o $deploy_package HEAD";
  };
};

after_task_finished 'deploy', sub {
  # Cleanup
  LOCAL {
    run "rm $deploy_package";
  }
};
