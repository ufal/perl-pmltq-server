package PMLTQ::Server::Controller::Admin::Sticker;

# ABSTRACT: Managing stickers in administration

use Mojo::Base 'Mojolicious::Controller';
use Mango::BSON 'bson_oid';
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

  if ( my $sticker_data = $c->_validate_sticker($c->param('sticker')) ) {
    my $stickers = $c->mandel->collection('sticker');
    my $sticker = $stickers->create($sticker_data);
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

  $sticker->remove(sub {
    my($sticker, $err) = @_;

    if ($err) {
      $c->flash(error => "$err");
      $c->stash(sticker => $sticker);
      $c->render(template => 'admin/stickers/form');
    } else {
      $c->redirect_to('list_stickers');
    }
  });

  $c->render_later;
}

sub _validate_sticker {
  my ($c, $sticker_data, $sticker) = @_;

  $sticker_data ||= {};

  $sticker_data = {
    %$sticker_data
  };
  my $rules = {
    fields => [qw/name comment parent/],
    filters => [
      # Remove spaces from all
      name => filter(qw/trim strip/),
      parent => to_dbref(PMLTQ::Server::Model::Sticker->model->collection_name)
    ],
    checks => [
      [qw/name comment/] => is_long_at_most(200),
      name => [is_required(), sub {
        my $stickername = shift;
        my $count = $c->mandel->collection('sticker')->search({
          stickername => $stickername,
          ($sticker ? (_id => { '$ne' => $sticker->id }) : ())
        })->count;
        return $count > 0 ? "sticker name '$stickername' already exists" : undef;
      }],
      parent => sub {
        my $parent = shift;
        return undef unless $sticker;
        return undef unless $parent;
        $parent = $c->mandel->collection('sticker')->search({_id  => $parent->{'$id'} })->single;
        
        return ($parent->has_sticker($sticker)) ? "sticker structure is not tree" : undef; 
        
      }
    ]
  };

  return $c->do_validation($rules, $sticker_data);
}

1;
