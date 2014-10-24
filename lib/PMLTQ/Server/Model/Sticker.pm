package PMLTQ::Server::Model::Sticker;

use PMLTQ::Server::Document 'stickers';
use Types::Standard qw(Str ArrayRef);

field [qw/name comment/] => (isa => Str);
field parent => 'PMLTQ::Server::Model::Sticker'; ############   ATTENTION - THE STRUCTURE OF STICKERS CAN BE RECURSIVE

sub has_sticker {
  my ($self, $sticker) = @_;
  my %seen;
  my @sticker_list = ($self->stickers);
  while(my $stickers = shift @sticker_list)
  {  
    return 1 if any { $_->name||'' eq $sticker } @{$stickers};
    for my $s (@{$stickers})
    {
      push @sticker_list, $s unless defined $seen{$s->name};
      $seen{$s->name}=1;
    }
  }
  return 0;
}

sub full_name {
  my ($self) = @_;
  my $name = "/".$self->name;
  $name = $self->parent->full_name . $name if $self->parent;
  return $name;
}




