package PMLTQ::Server::MultipleFileConfig;

use v5.10;
use strict;
use warnings;
use parent 'Mojolicious::Plugin';

use Config::Any;
use File::Spec::Functions;

sub register
{
	my $self = shift;
	my $app  = shift;
	my $arg  = shift;
	my $config = {};
	my @files;

	# Default args if not set
	$arg->{dir}     //= catfile($app->home, 'config');

	for (my $i = 0; $i < @{$arg->{files}}; $i++) {
		# Prefix dir
		$arg->{files}->[$i] = catfile($arg->{dir}, $arg->{files}->[$i]);
	}

	# Load the config file(s)
	my $config_tmp = Config::Any->load_files({
		files           => $arg->{files},
		use_ext         => 1,
		flatten_to_hash => 1,
		driver_args => {
			General => {-UTF8 => 1},
		},
		%$arg
	});

	# Merge
	for (@{$arg->{files}}){
		if(-e $_) {
		  $config = {%$config, %{$config_tmp->{$_}}};
		} else {
			$app->log->debug(__PACKAGE__ . ': cannot find ' . $_);
	  }
  }

	$app->config($config);
	$app->log->debug($app->dumper($config));

	return $config;
}

=head1 AUTHOR
this plugin is based on Mojolicious::Plugin::MultiConfig 0.2
Ben Vinnerd, C<< <ben at vinnerd.com> >> 2013

=cut

1;
