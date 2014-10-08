package PMLTQ::Server::Controller::Admin::Treebank;

# ABSTRACT: Handling everything related to treebanks

use Mojo::Base 'Mojolicious::Controller';
use Mango::BSON qw/bson_oid bson_dbref/;
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
  if(my $treebank_data = $c->_validate_treebank($c->param('treebank')) ){
    my $treebanks = $c->mandel->collection('treebank');
    my $treebank = $treebanks->create($treebank_data);

    $treebank->save(sub {
      my ($treebank, $err) = @_;
      if ($err) {
        $c->flash(error => "$err");
        print STDERR "ERROR $err\n";
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
    $c->render(template => 'admin/treebanks/form', status => 400);
  }
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
  #my $validator = _get_treebank_form_validation($c,$treebank->id);
  # PMLTQ::Server::Validation::fix_fields($validator, $c->param('treebank'));
  if (my $treebank_data = $c->_validate_treebank($c->param('treebank'), $treebank->id) ){
    $treebank->patch($treebank_data, sub {
      my($treebank, $err) = @_;
      $c->flash(error => "$err") if $err;
      $c->stash(treebank => $treebank);
      $c->render(template => 'admin/treebanks/form');
    });
    $c->render_later;  
  } else {
    $c->flash(error => "Can't save invalid treebank" );
    $c->flash(errors => $c->validator_error());
    $c->render(template => 'admin/treebanks/form', status => 400);
  }
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
      return;
    }

    $c->users->_storage_collection->update(
      {}, 
      { '$pull' => { available_treebanks => bson_dbref($treebank->model->collection_name, $treebank->id) } },
      { multi => 1 },
      sub {
        $c->redirect_to('list_treebanks');
      }
    );
  });

  $c->render_later;
}

sub _validate_treebank {
  my $c = shift;
  my $treebank_data = shift;
  my $id = shift;

  my $rules = {
    fields => [qw/name title driver host port database username password public anonaccess/],
    filters => [
      # Remove spaces from all
      [qw/name title host port database username password/] => filter(qw/trim strip/),
      public => force_bool(),
      anonaccess => force_bool()
    ],
    checks => [
      [qw/name title username password/] => is_long_at_most(200),
      [qw/name title driver host port database username/] => is_required(),
      $id ? () : (password => is_required()),
      port => is_valid_port_number(),
      driver => is_in_str("Driver is not supported", map {$_->[0]} @{$c->drivers}),
      name => is_not_in("Treebank name already exists", map {$_->name} grep {! $id or !($id eq $_->id)} @{$c->treebanks->all})
    ]
  };

  return $c->do_validation($rules, $treebank_data);
}

1;
