package PMLTQ::Server::Controller::Admin::Sticker;

# ABSTRACT: Managing stickers in administration

use Mojo::Base 'Mojolicious::Controller';
use Mango::BSON qw/bson_oid bson_dbref/;
use PMLTQ::Server::Validation;
use PMLTQ::Server::Model::Sticker ();

=head1 METHODS

=head2 list

List all stickers in the database

=cut




sub list {
  my $c = shift;

  $c->mandel->collection('sticker')->all(sub {
    my($collection, $err, $stickers) = @_;

    $c->flash(error => "Database Error: $err") if $err;

    $c->stash(stickers => $stickers);
    $c->render(template => 'admin/stickers/list');
  });

  $c->render_later;
}

sub new_sticker {
  my $c = shift;
  $c->stash(sticker => undef);
  $c->render(template => 'admin/stickers/form');
}

sub create {
  my $c = shift;

  if ( my $sticker=PMLTQ::Server::Model::Sticker::create_sticker($c,$c->param('sticker')) ) {
    $sticker->save(sub {
      my ($sticker, $err) = @_;
      if ($err) {
        $c->flash(error => "Database Error: $err");
        $c->stash(sticker => $sticker);
        $c->render(template => 'admin/stickers/form');
      } else {
        $c->redirect_to('show_sticker', id => $sticker->id);
      }
    });

    $c->render_later;
  } else {
    $c->flash(error => "Can't save invalid sticker");
    $c->render(template => 'admin/stickers/form', status => 400);
  }
}


sub find_sticker {
  my $c = shift;
  my $sticker_id = $c->param('id');

  $c->mandel->collection('sticker')->search({_id => bson_oid($sticker_id)})->single(sub {
    my($stickers, $err, $sticker) = @_;

    if ($err) {
      $c->flash(error => "$err");
      $c->render_not_found;
      return 0;
    }

    $c->stash(sticker => $sticker);
    $c->continue;
  });

  return undef;
}

sub show {
  my $c = shift;
  $c->render(template => 'admin/stickers/form');
}

sub update {
  my $c = shift;
  my $sticker = $c->stash->{sticker};

  if ( my $sticker_data = $c->_validate_sticker($c->param('sticker'), $sticker) ) {
    $sticker->patch($sticker_data, sub {
      my($sticker, $err) = @_;

      $c->flash(error => "$err") if $err;
      $c->stash(sticker => $sticker);
      $c->render(template => 'admin/stickers/form');
    });

    $c->render_later;
  } else {
    $c->flash(error => "Can't save invalid sticker");
    $c->render(template => 'admin/stickers/form', status => 400);
  }
}

sub remove {
  my $c = shift;
  my $sticker = $c->stash->{sticker};
  my $err = $c->_recursive_remove($sticker);
  if ($err) {
    $c->flash(error => "$err");
    $c->stash(sticker => $sticker);
    $c->render(template => 'admin/stickers/form');
  } else {
    $c->redirect_to('list_stickers');
  }

  $c->render_later;
}

sub _recursive_remove {
  my ($c,$sticker) = @_;
  # remove stickers for which is $sticker parent
  $c->_recursive_remove($_) for (grep {$_->parent && $_->parent->id eq $sticker->id} @{$c->mandel->collection('sticker')->all()});
  # remove sticker from users
  $c->users->_storage_collection->update(
      {},
      { '$pull' => { stickers => bson_dbref($sticker->model->collection_name, $sticker->id) } },
      { multi => 1 }
    );
  # remove sticker from treebanks
  $c->treebanks->_storage_collection->update(
      {},
      { '$pull' => { stickers => bson_dbref($sticker->model->collection_name, $sticker->id) } },
      { multi => 1 }
    );
  $sticker->remove();
  return;
}



sub _validate_sticker {
  my ($c, $sticker_data, $sticker) = @_;

  return PMLTQ::Server::Model::Sticker::validate_sticker($c,$sticker_data, $sticker);
}


1;
