package PMLTQ::Server::Config;

use Mojo::Base 'Mojolicious::Plugin';

use Config::Any;
use File::Spec;

my $config;

sub register {
  my ($self, $app) = @_;

  $config = $self->load_config($app) unless $config;
	$app->config($config);

	return $config;
}

sub load_config {
  my ($self, $app) = @_;

  my $config_dir = $app->home->rel_file('config');
  my @files = map { File::Spec->catfile($config_dir, $_) }
              ('pmltq_server.pl', 'pmltq_server.private.pl', 'pmltq_server.' . $app->mode . '.pl');

  my $configs = Config::Any->load_files({
    files           => \@files,
    use_ext         => 1,
    flatten_to_hash => 1,
    driver_args => {
      General => {-UTF8 => 1},
    },
  });

  # merge configs
  return { map %{$configs->{$_}}, grep ref $configs->{$_} eq 'HASH', @files }
}

1;
