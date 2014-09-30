package PMLTQ::Server::Validation;

use Mojo::Base -strict;
use Mojo::Util 'monkey_patch';
use Mango::BSON qw/bson_oid bson_dbref/;
use Email::Valid;
use Validate::Tiny;
use List::Util qw(first);

my @EXPORT_OK = qw/
  convert_to_oids
  force_arrayref
  force_bool
  is_valid_email
  list_of_dbrefs
  is_valid_port_number
  is_valid_driver
  is_not_in
  is_in_str
/;

# stuff from Validate::Tiny
my @VALIDATE_TINY_EXPORT = (qw/
  filter
  is_required
  is_required_if
  is_equal
  is_long_between
  is_long_at_least
  is_long_at_most
  is_a
  is_like
  is_in
/);

sub import {
  my $class = shift;
  my $caller = caller;

  no strict 'refs';
  *{"$caller\::$_"} = \&{"$class\::$_"} for @EXPORT_OK;
  *{"$caller\::$_"} = \&{"Validate::Tiny\::$_"} for @VALIDATE_TINY_EXPORT;

  Mojo::Base->import(-strict);
}

sub force_bool { sub { !!$_[0] ? 1 : 0 } }

sub force_arrayref { sub { $_[0] ? (ref($_[0]) eq 'ARRAY' ? $_[0] : [$_[0]]) : [] } }

sub convert_to_oids { sub { $_[0] && @$_[0] > 0 ? [map { bson_oid($_) } @$_[0]] : $_[0] } }

sub list_of_dbrefs {
  my $collection_name = shift;
  sub {
    my $arg = shift;
    my @list = $arg ? (ref($arg) eq 'ARRAY' ? @$arg : ($arg)) : ();
    @list = map { bson_oid($_) } @list if @list > 0 && !UNIVERSAL::isa($list[0], 'Mango::BSON::ObjectID');
    return [ map { bson_dbref($collection_name, $_) } @list ];
  }
}

sub is_valid_email {
  sub {
    my $email = shift;
    return undef unless $email;
    Email::Valid->address($email) ? undef : 'Invalid email'
  }
}

sub is_valid_port_number {
  sub {
    my $port = shift;
    ($port =~ m/^\d+$/ and $port>=1 and $port <= 65535) ? undef : 'Invalid port number'
  }
}

sub is_in_str {
  my $error = shift;
  my @list = @_;
  sub {
    my $str = shift;
    ( first {$str eq $_} @list) ? undef : $error
  }
}

sub is_not_in {
  my $error = shift;
  my @list = @_;
  sub {
    my $str = shift;
    (! (first {$str eq $_} @list)) ? undef : $error
  }
}
1;
