use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Test::Deep;
use File::Basename 'dirname';
use File::Spec;
use Mojo::JSON;

use lib dirname(__FILE__);

require 'bootstrap.pl';

start_postgres();
my $t = test_app();
my $tu = test_user();
my $tb = test_treebank();
my $tg1 = test_tag('TAG1','TAG1DOC');
my $tg2 = test_tag('TAG2','TAG2DOC');
my $tg1nodoc = test_tag('TAG1NODOC');
my $tg2nodoc = test_tag('TAG2NODOC');

# Test model

## Metadata
my $m = $tb->get_metadata;
my @all_metadata = qw/id name title description documentation homepage tags languages is_public is_all_logged is_free is_featured handle attributes doc node_types relations schemas/;
ok(cmp_bag(
  [keys %$m],
  [@all_metadata]
));

## Evaluator
my $e1 = $tb->get_evaluator;
isa_ok($e1, 'PMLTQ::SQLEvaluator');

my $e2 = $tb->get_evaluator;
isa_ok($e2, 'PMLTQ::SQLEvaluator');

is($e1, $e2, 'Evaluators are the same');

## History tested in history.t

## Search

my ($sth, $returns_nodes, $query_nodes, $evaluator) =
$tb->run_query(
  query => 'a-node []',
  use_cursor => 1,
);

{
  my @results;
  while (my $row = $evaluator->cursor_next()) {
    push @results, $row;
  }
  my $expected_result = [
    [ '2/a-node@a-ln94210-2-p1s1w1' ], [ '3/a-node@a-ln94210-2-p1s1w2' ], [ '4/a-node@a-ln94210-2-p1s1w3' ],
    [ '6/a-node@a-ln94210-2-p2s1w24' ], [ '7/a-node@a-ln94210-2-p2s1w1' ], [ '8/a-node@a-ln94210-2-p2s1w3' ],
    [ '9/a-node@a-ln94210-2-p2s1w2' ], [ '10/a-node@a-ln94210-2-p2s1w4' ], [ '11/a-node@a-ln94210-2-p2s1w6' ],
    [ '12/a-node@a-ln94210-2-p2s1w5' ], [ '13/a-node@a-ln94210-2-p2s1w7' ], [ '14/a-node@a-ln94210-2-p2s1w11' ],
    [ '15/a-node@a-ln94210-2-p2s1w8' ], [ '16/a-node@a-ln94210-2-p2s1w9' ], [ '17/a-node@a-ln94210-2-p2s1w10' ],
    [ '18/a-node@a-ln94210-2-p2s1w12' ], [ '19/a-node@a-ln94210-2-p2s1w13' ], [ '20/a-node@a-ln94210-2-p2s1w18' ],
    [ '21/a-node@a-ln94210-2-p2s1w14' ], [ '22/a-node@a-ln94210-2-p2s1w16' ], [ '23/a-node@a-ln94210-2-p2s1w15' ],
    [ '24/a-node@a-ln94210-2-p2s1w17' ], [ '25/a-node@a-ln94210-2-p2s1w20' ], [ '26/a-node@a-ln94210-2-p2s1w19' ],
    [ '27/a-node@a-ln94210-2-p2s1w21' ], [ '28/a-node@a-ln94210-2-p2s1w23' ], [ '29/a-node@a-ln94210-2-p2s1w22' ],
    [ '30/a-node@a-ln94210-2-p2s1w26' ], [ '31/a-node@a-ln94210-2-p2s1w25' ], [ '32/a-node@a-ln94210-2-p2s1w27' ],
    [ '34/a-node@a-ln94210-2-p3s1w10' ], [ '35/a-node@a-ln94210-2-p3s1w1' ], [ '36/a-node@a-ln94210-2-p3s1w2' ],
    [ '37/a-node@a-ln94210-2-p3s1w6' ], [ '38/a-node@a-ln94210-2-p3s1w4' ], [ '39/a-node@a-ln94210-2-p3s1w3' ],
    [ '40/a-node@a-ln94210-2-p3s1w5' ], [ '41/a-node@a-ln94210-2-p3s1w7' ], [ '42/a-node@a-ln94210-2-p3s1w9' ],
    [ '43/a-node@a-ln94210-2-p3s1w8' ], [ '44/a-node@a-ln94210-2-p3s1w11' ], [ '45/a-node@a-ln94210-2-p3s1w12' ],
    [ '46/a-node@a-ln94210-2-p3s1w14' ], [ '47/a-node@a-ln94210-2-p3s1w13' ], [ '48/a-node@a-ln94210-2-p3s1w15' ],
    [ '49/a-node@a-ln94210-2-p3s1w16' ], [ '51/a-node@a-ln94210-2-p3s2w2' ], [ '52/a-node@a-ln94210-2-p3s2w1' ],
    [ '53/a-node@a-ln94210-2-p3s2w4' ], [ '54/a-node@a-ln94210-2-p3s2w3' ], [ '55/a-node@a-ln94210-2-p3s2w7' ],
    [ '56/a-node@a-ln94210-2-p3s2w5' ], [ '57/a-node@a-ln94210-2-p3s2w6' ], [ '58/a-node@a-ln94210-2-p3s2w8' ],
    [ '59/a-node@a-ln94210-2-p3s2w9' ], [ '61/a-node@a-ln94210-2-p3s3w13' ], [ '62/a-node@a-ln94210-2-p3s3w7' ],
    [ '63/a-node@a-ln94210-2-p3s3w1' ], [ '64/a-node@a-ln94210-2-p3s3w3' ], [ '65/a-node@a-ln94210-2-p3s3w2' ],
    [ '66/a-node@a-ln94210-2-p3s3w4' ], [ '67/a-node@a-ln94210-2-p3s3w6' ], [ '68/a-node@a-ln94210-2-p3s3w5' ],
    [ '69/a-node@a-ln94210-2-p3s3w8' ], [ '70/a-node@a-ln94210-2-p3s3w9' ], [ '71/a-node@a-ln94210-2-p3s3w10' ],
    [ '72/a-node@a-ln94210-2-p3s3w12' ], [ '73/a-node@a-ln94210-2-p3s3w11' ], [ '74/a-node@a-ln94210-2-p3s3w17' ],
    [ '75/a-node@a-ln94210-2-p3s3w15' ], [ '76/a-node@a-ln94210-2-p3s3w14' ], [ '77/a-node@a-ln94210-2-p3s3w16' ],
    [ '78/a-node@a-ln94210-2-p3s3w18' ], [ '79/a-node@a-ln94210-2-p3s3w19' ], [ '80/a-node@a-ln94210-2-p3s3w20' ],
    [ '81/a-node@a-ln94210-2-p3s3w22' ], [ '82/a-node@a-ln94210-2-p3s3w21' ], [ '83/a-node@a-ln94210-2-p3s3w23' ],
    [ '85/a-node@a-ln94210-2-p3s4w3' ], [ '86/a-node@a-ln94210-2-p3s4w2' ], [ '87/a-node@a-ln94210-2-p3s4w1' ],
    [ '88/a-node@a-ln94210-2-p3s4w4' ], [ '89/a-node@a-ln94210-2-p3s4w5' ], [ '90/a-node@a-ln94210-2-p3s4w6' ],
    [ '91/a-node@a-ln94210-2-p3s4w7' ], [ '92/a-node@a-ln94210-2-p3s4w8' ], [ '93/a-node@a-ln94210-2-p3s4w9' ],
    [ '94/a-node@a-ln94210-2-p3s4w10' ], [ '95/a-node@a-ln94210-2-p3s4w12' ], [ '96/a-node@a-ln94210-2-p3s4w11' ],
    [ '97/a-node@a-ln94210-2-p3s4w13' ], [ '99/a-node@a-ln94210-39-p1s1w3' ], [ '100/a-node@a-ln94210-39-p1s1w2' ],
    [ '101/a-node@a-ln94210-39-p1s1w1' ], [ '102/a-node@a-ln94210-39-p1s1w4' ], [ '103/a-node@a-ln94210-39-p1s1w5' ],
    [ '104/a-node@a-ln94210-39-p1s1w6' ], [ '106/a-node@a-ln94210-39-p2s1Aw1' ], [ '107/a-node@a-ln94210-39-p2s1Aw2' ],
    [ '109/a-node@a-ln94210-39-p2s1Bw5' ]
  ];
  ok(cmp_deeply(\@results, $expected_result), 'Result is ok');
}

## Locating files
{
  my $data_dir = File::Spec->catdir(dirname(__FILE__), 'test_files');
  my @files = qw(sample0 sample1);
  my @layers = qw(a m t w);

  for my $filebase (@files) {
    for my $layer (@layers) {
      my $filename = "${filebase}.${layer}.gz";
      my $schema = $layer =~ m/(m|w)/ ? 'adata' : "${layer}data";
      my ($schema_name,$data_dir,$new_filename) = $tb->locate_file($filename);
      is($schema_name, $schema, "${schema} schema ok");
      #is($data_dir, '/ha/work/projects/pmltq/data/pdt20_mini/data', 'Data dir ok');
    }
  }

  for my $filebase (@files) {
    for my $layer (@layers) {
      my $filename = "${filebase}.${layer}.gz";

      my $path = $tb->resolve_data_path($filename, $data_dir);
      ok(-e $path, "$filename path exists");
    }
  }

  # Locate all schema files
  # TODO: this result is bad, it should point to real file
  for my $layer (qw(a t)) {
    my $schema_file = "${layer}data_schema.xml";
    my $path = $tb->resolve_data_path($schema_file, $data_dir);
    is($path, "/ha/work/projects/pmltq/data/pdt20_mini/resources/$schema_file", "$schema_file path is ok");
  }
}

# Test routes
ok $t->app->routes->find('treebanks'), 'Treebanks route exists';
my $treebanks_url = $t->app->url_for('treebanks');
ok ($treebanks_url, 'Treebanks url');

$t->get_ok($treebanks_url)
  ->status_is(200);

is(scalar(@{$t->tx->res->json}), 1, 'Returned one treebank');
$t->json_is("/0/$_", $tb->$_) for (qw/id name title description homepage/);
$t->json_hasnt("/0/documentation", "treebank has documentation field in list");

# Set public to false
$tb->is_public(0);
$tb->update();

$t->get_ok($treebanks_url)
  ->status_is(200);

is(scalar(@{$t->tx->res->json}), 0, 'Returned no treebank');

ok $t->app->routes->find('treebank'), 'Single treebank route exists';

# URL with ID
my $treebank_url = $t->app->url_for('treebank', treebank_id => $tb->id);

$t->get_ok($treebank_url)
  ->status_is(200);

my @returned_keys = qw/id name title description homepage/;

$t->json_is("/$_", $tb->$_) for @returned_keys;
$t->json_has("/documentation", "Treebank has documentation field");

# URL with name
$treebank_url = $t->app->url_for('treebank', treebank_id => $tb->name);
my $treebank_url_documentation = $t->app->url_for('documentation', treebank_id => $tb->name);

$t->get_ok($treebank_url)
  ->status_is(200);

$t->json_is("/$_", $tb->$_) for @returned_keys;
$t->json_has("/documentation", "Treebank has documentation field");

# testing documentation and tag documentation
$tb->add_to_tags($tg1);
$tb->metadata(undef);
$tb->update();

$t->get_ok($treebank_url)
  ->status_is(200);

$t->json_has("/tags", "treebank has tag field");
is(scalar(@{$t->tx->res->json->{tags}}), 1, 'Treebank has one tag');
$t->json_hasnt("/tags/0/documentation", "Tag documentation is not sended in tag");
ok($t->tx->res->json->{documentation}, 'Treebank has documentation');

$t->get_ok($treebank_url_documentation)
  ->status_is(200);
is($t->tx->res->json->{documentation}, $tg1->documentation, 'Treebank uses TAG1 documentation');


# testing concatenation of tags documentation
$tb->add_to_tags($tg2);
$tb->metadata('HACK');$tb->metadata(undef); # you must set some different value and then undef to remove metadata
$tb->update();

$t->get_ok($treebank_url)
  ->status_is(200);

is(scalar(@{$t->tx->res->json->{tags}}), 2, 'Treebank has two tags');
my ($tg1doc,$tg2doc) = map {$_->documentation} ($tg1,$tg2);
ok($t->tx->res->json->{documentation}, 'Treebank has documentation');

$t->get_ok($treebank_url_documentation)
  ->status_is(200);
ok($t->tx->res->json->{documentation} =~ /^\s*(\Q$tg1doc\E\s*\Q$tg2doc\E|\Q$tg2doc\E\s*\Q$tg1doc\E)\s*$/, 'Treebank uses concatenation of TAG1 and TAG2 documentation (dont care about order) and nothing more');

# use treebank documentation when is set
$tb->documentation('TBDOC');
$tb->update();

$t->get_ok($treebank_url)
  ->status_is(200);

ok($t->tx->res->json->{documentation}, 'Treebank has documentation');

$t->get_ok($treebank_url_documentation)
  ->status_is(200);
is($t->tx->res->json->{documentation}, $tb->documentation, 'Treebank uses treebank documentation');

# test two tags without doc and treebank without doc
$tb->documentation('');
$tb->set_tags([$tg1nodoc,$tg2nodoc]);
$tb->update();

$t->get_ok($treebank_url)
  ->status_is(200);

is($t->tx->res->json->{documentation}, 0, 'Treebank does not have documentation');
$t->get_ok($treebank_url_documentation)
  ->status_is(200);
is($t->tx->res->json->{documentation}, '', 'Treebank does not have documentation');


# test /treebanks/:treebank_id/node-types route
my $treebank_url_nodetype = $t->app->url_for('node_types', treebank_id => $tb->name);

$t->get_ok($treebank_url_nodetype)
  ->status_is(200);
$t->json_has("/types", "node-types response has types field");
ok(cmp_bag($t->tx->res->json->{types}, [qw/a-node a-root t-node t-root/]),"types ok");

$t->get_ok($treebank_url_nodetype => form => {layer => 'adata'})
  ->status_is(200);
$t->json_has("/types", "node-types response has types field");
ok(cmp_bag($t->tx->res->json->{types}, [qw/a-node a-root/]),"types ok");

# test /treebanks/:treebank_id/relations route
my $treebank_url_relations = $t->app->url_for('relations', treebank_id => $tb->name);
# ...TODO...

# test /treebanks/:treebank_id/schema route
# ...TODO...
my $treebank_url_schema = $t->app->url_for('schema', treebank_id => $tb->name);


done_testing();
