use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use File::Basename 'dirname';
use File::Spec;

use lib dirname(__FILE__);

require 'bootstrap.pl';

my $t = test_app();

ok($t, 'App is alive');

done_testing();
