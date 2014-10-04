package PMLTQ::Server::Helpers;

use Mojo::Base 'Mojolicious::Plugin';
use Mango::BSON 'bson_oid';
use Digest::SHA qw(sha1_hex);

use List::Util qw(min any);
use Scalar::Util ();

sub register {
  my ($self, $app, $conf) = @_;
  $app->helper(mango => sub { shift->app->db });
  $app->helper(mandel => sub { shift->app->mandel });
  $app->mandel->initialize;

  # History
  $app->helper(history_key => \&_history_key);

  # Add admin user if not present
  $app->mandel->collection('user')->count(sub {
    my ($users, $err, $int) = @_;

    return unless ($int == 0 && !$err);
    $app->mandel->collection('permission')->search({name => 'admin'})->single(sub {
      my($permissions, $err, $admin_permission) = @_;
      unless ($admin_permission) {
        $admin_permission = $permissions->create({
          name => 'admin',
          comment => 'All powerfull admin'
        });
        $admin_permission->save();
      }

      my $admin = $users->create({
        name => 'Super Admin',
        username => 'admin',
        password => 'admin',
      });

      $admin->save(sub {
        my ($admin, $err) = @_;

        $app->log->error("Creating admin user failed: $err") if $err;
        $admin->push_permissions($admin_permission) if ($admin);
      });
    });
  });

  # Generate field options from database collection
  # Example: field_options('user', values_accessor => label_accessor)
  $app->helper(field_options => sub {
    my ($self, $name, $id_accessor, $label_accessor) = @_;
    $id_accessor //= 'id';
    $label_accessor //= 'label';

    return {
      map {
        ($_->$id_accessor => $_->$label_accessor)
      } @{$self->mandel->collection($name)->all}
    }
  });

  # Common access helpers
  $app->helper(users         => sub { shift->mandel->collection('user') });
  $app->helper(treebanks     => sub { shift->mandel->collection('treebank') });
  $app->helper(permissions   => sub { shift->mandel->collection('permission') });
  $app->helper(history       => sub { shift->mandel->collection('history') });
  $app->helper(drivers       => sub { state $drivers = [ [Pg => 'PostgreSQL'] ] });

  # ERROR
  $app->helper(status_error => \&_status_error);
}

sub _history_key {
  my $self = shift;

  my $current_user = $self->current_user;
  return $current_user->id if $current_user;

  my $key = $self->session->{history_key};
  unless ($key) {
    $key = sha1_hex(time() . rand() . (2 * rand()));
    $self->session(history_key => $key);
  }
  return $key;
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


1;
