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

group all => 'euler';

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
  my $deploy_current = "$deploy_to/current";
  unless (is_dir($deploy_dir)) {
    Rex::Logger::debug("rmdir $deploy_dir");
    rmdir $deploy_dir;
  }
  mkdir $deploy_dir;
  run "cd $deploy_dir; unzip /tmp/$deploy_package";

  my $live_version = eval {
    readlink $deploy_current;
  };
  $live_version = basename($live_version) if $live_version;

  run "ln -snf $deploy_dir $deploy_current";

  unlink "/tmp/$deploy_package";

  my $shared_dir = "$deploy_to/shared";
  unless (is_dir($shared_dir)) {
    mkdir $shared_dir;
  }

  # Keep logs in shared directory
  unless (is_dir("$shared_dir/log")) {
    mkdir "$shared_dir/log";
  }

  if (is_dir("$live_version/local")) {
    cp "$live_version/local", "$deploy_current/local"
  }

  my $config_file = "$shared_dir/pmltq_server.private.pl";
  my $start_server = 1;
  unless (is_file($config_file)) {
    cp ("$deploy_dir/config/pmltq_server.private.pl.example", $config_file);
    $start_server = 0;
  }
  run "ln -snf $config_file $deploy_to/current/config/pmltq_server.private.pl";

  rmdir "$deploy_dir/log";
  run "ln -snf $shared_dir/log $deploy_dir/log";

  # install dependecies
  Rex::Logger::info("Installing dependecies...");
  run 'installdeps',
    cwd => $deploy_dir,
    command => '[[ -s "$HOME/perl5/perlbrew/etc/bashrc" ]] && source $HOME/perl5/perlbrew/etc/bashrc && carton install';

  if ($start_server) {
    my $pid_file = "$shared_dir/pmltq-server.pid";
    if (is_file($pid_file)) {
      run '[[ -s "$HOME/perl5/perlbrew/etc/bashrc" ]] && source $HOME/perl5/perlbrew/etc/bashrc && ubic restart pmltq';
    } else {
      run '[[ -s "$HOME/perl5/perlbrew/etc/bashrc" ]] && source $HOME/perl5/perlbrew/etc/bashrc && ubic start pmltq';
    }
  } else  {
    Rex::Logger::info("Not starting server, edit $config_file first");
  }

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
