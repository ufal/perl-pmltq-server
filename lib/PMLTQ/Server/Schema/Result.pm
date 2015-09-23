package PMLTQ::Server::Schema::Result;

use Mojo::Base qw/DBIx::Class::Core/;
use PMLTQ::Server::JSON qw/json_key/;
use Mojo::JSON;

__PACKAGE__->load_components(qw/InflateColumn::DateTime TimeStamp FilterColumn::ByType/);

__PACKAGE__->filter_columns_by_type( boolean => {
  filter_to_storage => sub { $_[1] ? 1 : 0 },
  filter_from_storage => sub { $_[1] ? Mojo::JSON->true : Mojo::JSON->false },
});

__PACKAGE__->mk_group_accessors(inherited => '_serializable_columns');

my $dont_serialize = {
   text  => 1,
   ntext => 1,
   blob  => 1,
};

sub _is_column_serializable {
   my ( $self, $column ) = @_;

   my $info = $self->column_info($column);

   if (!defined $info->{is_serializable}) {
    if (defined $info->{data_type} &&
      $dont_serialize->{lc $info->{data_type}}
    ) {
      $info->{is_serializable} = 0;
    } else {
      $info->{is_serializable} = 1;
    }
   }

   return $info->{is_serializable};
}

sub serializable_columns {
   my $self = shift;
   if (!$self->_serializable_columns) {
     $self->_serializable_columns([
        grep $self->_is_column_serializable($_),
           $self->result_source->columns
      ]);
   }
   return $self->_serializable_columns;
}

sub to_json_key {
  shift; json_key(@_);
}

sub TO_JSON {
   my $self = shift;

   my $columns_info = $self->columns_info($self->serializable_columns);

   return {
      map +(json_key($_) => $self->$_),
      map +($columns_info->{$_}{accessor} || $_),
          keys %$columns_info
   };
}

1;
