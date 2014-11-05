package PMLTQ::Server::Model::Sticker;

use PMLTQ::Server::Document 'stickers';
use Types::Standard qw(Str ArrayRef);

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




