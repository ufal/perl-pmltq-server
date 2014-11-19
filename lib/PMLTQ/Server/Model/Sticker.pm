package PMLTQ::Server::Model::Sticker;

use PMLTQ::Server::Document 'stickers';
use Types::Standard qw(Str ArrayRef);
use PMLTQ::Server::Controller::Admin::Sticker;
use PMLTQ::Server::Validation;

field [qw/name comment/] => (isa => Str);
belongs_to parent => 'PMLTQ::Server::Model::Sticker'; ############   ATTENTION - THE STRUCTURE OF STICKERS CAN BE RECURSIVE

has_many children => 'PMLTQ::Server::Model::Sticker';

sub has_sticker { 
  my ($self, $sticker) = @_;
  my %seen;
  my $parent = $self;
  while($parent and not defined $seen{$parent->id}) {
    return 1 if $parent->id eq $sticker->id ;
    $seen{$parent->id}=1;
    $parent = ($parent->parent and not defined $seen{$parent->parent->id}) ? $parent->parent : undef;
  }
  return 0;
}

sub full_name {
  my ($self) = @_;
  my $name = "/".$self->name;
  my $parent = $self->parent;
  my %seen;
  while($parent and not defined $seen{$parent->id}) {
    $seen{$parent->id}=1;
    $name = "/".$parent->name.$name;
    $parent = ($parent->parent and not defined $seen{$parent->parent->id}) ? $parent->parent : undef;
  }
  return $name;
}

sub create_sticker {
  my $c = shift;
  my $data = shift;
  my $sticker=undef;
  print STDERR "C=$c,data=$data\n";
  if ( my $sticker_data = validate_sticker($c,$data) ) {
    $sticker = $c->mandel->collection('sticker')->create($sticker_data);
  }
  return $sticker;
}

sub validate_sticker {
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
          name => $stickername,
          ($sticker ? (_id => { '$ne' => $sticker->id }) : ())
        })->count;
        return $count > 0 ? "name '$stickername' already exists" : undef;
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