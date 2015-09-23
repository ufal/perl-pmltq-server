package PMLTQ::Server::Validation;

use Mojo::Base -strict;
use Mojo::JSON;
use Crypt::Eksblowfish::Bcrypt qw(en_base64 bcrypt);
use Encode qw(is_utf8 encode_utf8);
use Email::Valid;
use Validate::Tiny;
use List::Util qw(first all);
use Exporter 'import';

# stuff from Validate::Tiny
my @VALIDATE_TINY_EXPORT = qw/
  filter
  is_a
  is_equal
  is_in
  is_like
  is_long_at_least
  is_long_at_most
  is_long_between
  is_required
  is_required_if
  /;

for (@VALIDATE_TINY_EXPORT) {
  no strict 'refs';
  *$_ = \&{"Validate::Tiny\::$_"};
}

my @VALIDATE_EXPORT = qw/
  check_password
  convert_to_oids
  encrypt_password
  force_arrayref
  force_bool
  is_array
  is_array_of_hash
  is_hash
  is_in_str
  is_not_in
  is_password_equal
  is_unique
  is_valid_driver
  is_valid_email
  is_valid_port_number
  list_of_dbrefs
  to_array_of_hash
  to_dbref
  to_hash
  /;

our @EXPORT_OK = ( @VALIDATE_EXPORT, @VALIDATE_TINY_EXPORT );

our @EXPORT = @EXPORT_OK;

sub force_bool {
  sub { !!$_[0] ? 1 : 0 }
}

sub force_arrayref {
  sub { $_[0] ? ( ref( $_[0] ) eq 'ARRAY' ? $_[0] : [ $_[0] ] ) : [] }
}

sub convert_to_oids {
  sub {
    $_[0] && @$_[0] > 0 ? [ map { bson_oid($_) } @$_[0] ] : $_[0];
  };
}

sub list_of_dbrefs {
  my $collection_name = shift;
  sub {
    my $arg = shift;
    my @list = $arg ? ( ref($arg) eq 'ARRAY' ? @$arg : ($arg) ) : ();
    @list = map { bson_oid($_) } @list if @list > 0 && !UNIVERSAL::isa( $list[0], 'Mango::BSON::ObjectID' );
    return [ map { bson_dbref( $collection_name, $_ ) } @list ];
  };
}

sub to_dbref {
  my $collection_name = shift;
  sub {
    my $arg = shift;
    return unless $arg;
    return  bson_dbref( $collection_name, bson_oid($arg) ) ;
  };
}

sub to_hash {
  my $delim   = shift;
  my $pattern = shift;
  sub {
    my $text = shift;
    my %h = map { m/$pattern/ ? ( $1 => $2 ) : ( 'ERROR' => undef ) } split( $delim, $text );
    return if exists( $h{'ERROR'} ) and not defined( $h{'ERROR'} );
    return \%h;
  };
}

sub to_array_of_hash {
  my $fields  = shift;
  my $delim   = shift;
  my $pattern = shift;
  sub {
    my $text = shift;
    my @a = ();
    for my $line (split( $delim, $text ))
    {
      next if $line =~ m/^\s$/;
      my @matched = $line =~ m/$pattern/;
      if(@matched and @matched == @$fields)
      {
        push @a, { map { $fields->[$_] => $matched[$_] } ( 0 .. $#$fields ) };
      }
      else
      {
        return;
      }
    }
    return \@a;
  };
}

sub _bcrypt {
  my ($plain_text, $settings) = @_;

  $plain_text = encode_utf8($plain_text) if is_utf8($plain_text);    #  Bcrypt expects octets
  bcrypt( $plain_text, $settings );
}

sub encrypt_password {
  my ($settings) = @_;

  unless ( defined $settings && !ref($settings) && $settings =~ /^\$2a\$/ ) {
    $settings ||= {};

    my $cost = exists $settings->{cost}    ? $settings->{cost}    : 8;
    my $nul  = exists $settings->{key_nul} ? $settings->{key_nul} : 1;
    my $salt = $settings->{salt};
    $salt = "T" x 16 if $ENV{MOJO_MODE} && $ENV{MOJO_MODE} eq 'test';
    $nul = $nul ? 'a' : '';
    $cost = sprintf( "%02i", 0 + $cost );
    if ($salt) {
      my $l = length $salt;
      $l = ( int( $l / 8 ) + 1 ) * 8 if $l % 8;
      $salt = sprintf( "%${l}s", $salt );
    }
    else {
      $salt = join( '', map { chr( int( rand(256) ) ) } 1 .. 16 ) unless $salt;
    }
    $settings = join( '', '$2', $nul, '$', $cost, '$', en_base64($salt) );
  }

  sub { defined( $_[0] ) && $_[0] ne '' ? _bcrypt($_[0], $settings) : undef };
}

sub check_password {
  my ($password, $password_check) = @_;
  return 0 unless $password && $password_check;
  return $password eq _bcrypt($password_check, $password)
}

sub is_password_equal {
  my ( $other, $err_msg ) = @_;
  $err_msg ||= 'Invalid value';
  sub {
    return if !defined( $_[0] ) || $_[0] eq '';
    return defined $_[1]->{$other} && check_password($_[0], $_[1]->{$other})
      ? undef
      : $err_msg;
  };
}

sub is_valid_email {
  sub {
    my $email = shift;
    return unless $email;
    Email::Valid->address($email) ? undef : 'Invalid email';
  };
}

sub is_valid_port_number {
  sub {
    my $port = shift;
    ( $port =~ m/^\d+$/ and $port >= 1 and $port <= 65535 ) ? undef : 'Invalid port number';
  };
}

sub is_in_str {
  my $error = shift;
  my @list  = @_;
  sub {
    my $str = shift;
    ( first { $str eq $_ } @list ) ? undef : $error;
  };
}

sub is_not_in {
  my $error = shift;
  my @list  = @_;
  sub {
    my $str = shift;
    ( !( first { $str eq $_ } @list ) ) ? undef : $error;
    }
}

sub is_unique {
  my ($resultset, $id_name, $error) = @_;
  sub {
    my ($value, $param, $key) = @_;
    my $rs = $resultset;
    if ($param->{$id_name}) {
      $rs = $rs->search({$id_name => {'!=' => $param->{$id_name}}});
    }
    $rs->search({$key => $value})->count ? $error : undef;
  }
}

sub is_hash {
  my $error = shift;
  sub {
    my $h = shift;
    return unless defined($h);
    ( ref($h) eq 'HASH' ) ? undef : $error;
  };
}

sub is_array {
  my $error = shift;
  sub {
    my $a = shift;
    return unless defined($a);
    ( ref($a) eq 'ARRAY' ) ? undef : $error;
  };
}

sub is_array_of_hash {
  my $error = shift;
  sub {
    my $a = shift;
    return unless defined($a);
    ( ref($a) eq 'ARRAY' and all { $_ and ref($_) eq 'HASH' } @$a ) ? undef : $error;
  };
}


1;
