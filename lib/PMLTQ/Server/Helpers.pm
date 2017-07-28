package PMLTQ::Server::Helpers;

use Mojo::Base 'Mojolicious::Plugin';
use PMLTQ::Server::JSON qw(perl_key);
use List::Util qw(min any);

sub register {
  my ($self, $app, $conf) = @_;
  $app->helper(db => sub { shift->app->db });

  $app->helper(history_limit => sub { shift->config->{history_limit} // 50 });
  # Resultsets
  $app->helper(public_treebanks => sub { shift->db->resultset('Treebank')->search_rs({ is_public => 1 }) });

  # Error helpers
  $app->helper(status_error => \&_status_error);
  $app->helper(render_validation_errors => \&_render_validation_errors);
  $app->helper(query_filter => sub {
    my ($self, $hash) = @_;

    for (keys %$hash) {
      my $value = delete $hash->{$_};
      $value = 1 if ($value eq 'true');
      $value = 0 if ($value eq 'false');
      $hash->{perl_key($_)} = $value;
    }

    return $hash;
  });

  # Fake PUT and DELETE methods
  $app->hook(before_dispatch => sub {
    my $c = shift;
    if (my $req_json = $c->req->json) {
      _snake_hashref($req_json);
    }
  });
}

sub _snake_hashref {
  my $hash = shift;

  for (keys %$hash) {
    if (ref $hash->{$_} eq 'HASH') {
      _snake_hashref($hash->{$_});
    }
    $hash->{perl_key($_)} = delete $hash->{$_};
  }
}

sub _status_error {
  my ($self, @errors) = @_;

  die __PACKAGE__, 'No errors to render' unless @errors;

  if (@errors == 1) {
    my $error = shift @errors;
    $self->res->code($error->{code});
    $self->render(json => { error => $error->{message} });
  } else {
    # find lowest code and display only those errors
    my $code = min map { $_->{code} } @errors;

    @errors = grep { $_->{code} == $code } @errors;
    return $self->status_error(@errors) if @errors == 1;

    $self->res->code($code);
    $self->render(json => {
      message => 'The request cannot be fulfilled because of multiple errors',
      errors => [ map { $_->{message} } @errors ]
    });
  }
}

sub _render_validation_errors {
  my $self = shift;

  my $errors = $self->stash('validate_tiny.errors');
  if ($errors && keys %$errors) {
    $self->status_error(map { { code => 400, message => $errors->{$_} } } keys %$errors);
  }
}

1;
