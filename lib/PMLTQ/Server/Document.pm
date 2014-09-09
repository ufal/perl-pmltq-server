package PMLTQ::Server::Document;

use Mandel::Document;

sub _resolve_lazy_fields {
  my $self = shift;

  for my $field ($self->model->fields) {
    my $field_name = $field->name;
    $self->$field_name();
  }
}

sub save {
  my $self = shift;
  $self->_resolve_lazy_fields;
  $self->SUPER::save(@_);
}

1;
