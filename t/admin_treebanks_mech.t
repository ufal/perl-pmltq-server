use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Test::WWW::Mechanize::Mojo;
use HTML::Lint::Pluggable;
use Mojo::DOM;

use File::Basename 'dirname';
use List::Util qw/first all/;

use lib dirname(__FILE__);

require 'bootstrap.pl';

my $t = test_app();

my $lint = HTML::Lint::Pluggable->new;
$lint->load_plugins(qw/HTML5/);

my $mech = Test::WWW::Mechanize::Mojo->new(tester => $t, autolint => $lint);

$mech->get_ok('/');
$mech->title_like(qr/Please Sign In/);
$mech->html_lint_ok('Login page html is ok');

$mech->submit_form_ok({
  form_name => 'auth',
  fields => {
    'auth.username' => 'admin',
    'auth.password' => 'admin'
  }
}, 'Login form ok');

$mech->title_like(qr/Overview/i);
$mech->html_lint_ok('Overview page html is ok');
$mech->follow_link_ok({ text_regex => qr/treebanks/i }, 'Click on Treebanks');

$mech->title_like(qr/List of Treebanks/i);
$mech->html_lint_ok('List of treebanks html is ok');

$mech->follow_link_ok({ text_regex => qr/add new treebank/i }, 'Click on Add new treebank');
$mech->html_lint_ok('Treebank form html is ok');

$mech->submit_form(
  form_name => 'treebank'
);

is($mech->status, 400, 'Empty form failed');
$mech->title_like(qr/New Treebank/i, 'Redirect after passed empty form');

my %treebank_data = (
  name => 'MY New treebank',
  title => 'TB',
  driver => 'Pg',
  host => '127.0.0.1',
  port => 5000,
  database => 'mytb',
  username => 'joe',
  password => 's3cret'
);

for my $key (grep {!("driver" eq $_)}keys %treebank_data){  
  # passes only the first iteration, the following are affected by fields which has been filled in preceding iteration
  # it fills preceding value to form
  my @fields = grep {!($key eq $_)} keys(%treebank_data);
  $mech->field("treebank.$key", '');
  $mech->submit_form(
    form_name => 'treebank',
    fields => { map { ("treebank.$_" => $treebank_data{$_}) } @fields}
  );
  is($mech->status, 400, "Required field treebank.$key not filled");
  $mech->title_like(qr/New Treebank/i, "Redirect after passed empty treebank.$key");
  for my $f (keys %treebank_data){ 
    is( $mech->value("treebank.$f"), $f eq $key ? '':$treebank_data{$f}, "treebank.$f is".($f eq $key ? " not":"")." filled when required treebank.$key is attempted to not be filled");
  }
}

$mech->submit_form_ok({
  form_name => 'treebank',
  fields => { map { ("treebank.$_" => $treebank_data{$_}) } keys %treebank_data }  
}, 'Add treebank without error');

# navigate back to the List of treebanks
$mech->follow_link_ok({ text_regex => qr/treebanks/i }, 'Click on Treebanks');
$mech->title_like(qr/List of Treebanks/i);
$mech->html_lint_ok('List of treebanks html is ok');
$mech->text_contains($treebank_data{name}, 'New treebank is in the list');
my $tbname=$treebank_data{name};
$mech->follow_link_ok({ text_regex => qr/$tbname/i }, 'Show treebank detail');
$mech->title_like(qr/Edit Treebank/i, 'Edit treebank');
for my $f (keys %treebank_data){
  is( $mech->value("treebank.$f"), $treebank_data{$f}, "treebank.$f is ok");
}


$treebank_data{name} = 'MY UPDATED treebank';
$mech->submit_form_ok({
  form_name => 'treebank',
  fields => { map { ("treebank.$_" => $treebank_data{$_}) } keys %treebank_data }  
}, 'Update treebank without error');

# navigate back to the List of treebanks
$mech->follow_link_ok({ text_regex => qr/treebanks/i }, 'Click on Treebanks');
$mech->title_like(qr/List of Treebanks/i);
$mech->html_lint_ok('List of treebanks html is ok');
$mech->text_contains($treebank_data{name}, 'New treebank is in the list');
$tbname=$treebank_data{name};
$mech->follow_link_ok({ text_regex => qr/$tbname/i }, 'Show treebank detail');
$mech->title_like(qr/Edit Treebank/i, 'Edit treebank');
for my $f (keys %treebank_data){
  is( $mech->value("treebank.$f"), $treebank_data{$f}, "treebank.$f is ok");
}

done_testing();