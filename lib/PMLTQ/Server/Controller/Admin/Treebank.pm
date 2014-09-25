package PMLTQ::Server::Controller::Admin::Treebank;

# ABSTRACT: Handling everything related to treebanks

use Mojo::Base 'Mojolicious::Controller';
use Mango::BSON 'bson_oid';
use PMLTQ::Server::Validation;


my $controller; ### little hack - it allows access to helpers from validation 


=head1 METHODS

=head2 initialize

Bridge for other routes. Saves current treebank to stash under 'tb' key.

=cut



sub list {
  my $c = shift;

  $c->mandel->collection('treebank')->all(sub {
    my($collection, $err, $treebanks) = @_;

    $c->flash(error => "Database Error: $err") if $err;

    $c->stash(treebanks => $treebanks);
    $c->render(template => 'admin/treebanks/list');
  });

  $c->render_later;
}

sub new_treebank {
  my $c = shift;
  $c->stash(treebank => undef);
  $c->render(template => 'admin/treebanks/form');
}

sub create {
  my $c = shift;
  if(my $treebank_data = $c->do_validation(_get_treebank_form_validation($c), $c->param('treebank')) ){
    my $treebanks = $c->mandel->collection('treebank');
    my $treebank = $treebanks->create($c->param('treebank'));

    $treebank->save(sub {
      my ($treebank, $err) = @_;
      if ($err) {
        $c->flash(error => "$err");
        $c->stash(treebank => $treebank);
        $c->render(template => 'admin/treebanks/form');
      } else {
        $c->redirect_to('show_treebank', id => $treebank->id);
      }
    });
    $c->render_later;  
  }else{
    $c->flash(error => "Can't save invalid treebank" );
    $c->flash(errors => $c->validator_error());
    $c->render(template => 'admin/treebanks/form');}
}

sub find_treebank {
  my $c = shift;
  my $treebank_id = $c->param('id');

  $c->mandel->collection('treebank')->search({_id => bson_oid($treebank_id)})->single(sub {
    my($treebanks, $err, $treebank) = @_;

    if ($err) {
      $c->flash(error => "$err");
      $c->render_not_found;
      return;
    }

    $c->stash(treebank => $treebank);
    $c->continue;
  });

  return undef;
}

sub show {
  my $c = shift;
  $c->render(template => 'admin/treebanks/form');
}

sub update {
  my $c = shift;
  my $treebank = $c->stash->{treebank};

  for (qw/visible public anonaccess/){$c->param('treebank')->{$_} = 0 unless $c->param('treebank')->{$_};}   #### checkboxes
  # TODO: validate input
  $treebank->patch($c->param('treebank'), sub {
    my($treebank, $err) = @_;

    $c->flash(error => "$err") if $err;
    $c->stash(treebank => $treebank);
    $c->render(template => 'admin/treebanks/form');
  });

  $c->render_later;
}

sub remove {
  my $c = shift;
  my $treebank = $c->stash->{treebank};

  $treebank->remove(sub {
    my($treebank, $err) = @_;

    if ($err) {
      $c->flash(error => "$err");
      $c->stash(treebank => $treebank);
      $c->render(template => 'admin/treebanks/form');
    } else {
      $c->redirect_to('list_treebanks');
    }
  });

  $c->render_later;
}


sub fetch {}

sub _get_treebank_form_validation{
  my $c = shift;
  my $treebank_form_validation = {
    fields => [qw/name title driver host port database username password visible public anonaccess/],
    filters => [
      # Remove spaces from all
      [qw/name title host port database username password/] => filter(qw/trim strip/),
      visible => force_bool(),
      public => force_bool(),
      anonaccess => force_bool()
    ],
    checks => [
      [qw/name title username password/] => is_long_at_most(200),
      [qw/name title driver host port database username password/] => is_required(),
      port => is_valid_port_number(),
      driver => is_in([$c->drivers,"Driver is not supported"]),
      name => is_not_in(["Treebank name already exists", map {$_->{name}} @{$c->treebanks->all}])
    ]
  };
  return $treebank_form_validation;
}

1;
