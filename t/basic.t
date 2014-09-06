use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use File::Basename 'dirname';
use File::Spec;
use lib File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..', 'lib'));

my $t = Test::Mojo->new('PMLTQ::Server');
$t->get_ok('/')->status_is(200);

done_testing();
