package PMLTQ::Server::Validation;

use Mojo::Base -strict;
use Mojo::Util 'monkey_patch';
use Mango::BSON qw/bson_oid bson_dbref/;
use Crypt::Eksblowfish::Bcrypt ();
use Encode qw(is_utf8 encode_utf8);
use Email::Valid;
use Validate::Tiny;
use List::Util qw(first all);
use Exporter 'import';

use Scalar::Util 'refaddr';

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

for (@VALIDATE_TINY_EXPORT) {
  no strict 'refs';
  *$_ = \&{"Validate::Tiny\::$_"}
}

our @EXPORT_OK = (qw/
  convert_to_oids
  force_arrayref
  force_bool
  to_hash
  to_array_of_hash
  is_valid_email
  list_of_dbrefs
  encrypt_text
  is_valid_port_number
  is_valid_driver
  is_not_in
  is_in_str
  is_array_of_hash
  is_hash
/, @VALIDATE_TINY_EXPORT);

our @EXPORT = @EXPORT_OK;

=xxx
experiments
sub fix_fields {
  my ($validator,$params) = @_;
  my %required;
  my $req = \&is_required;
  my %checks = @{$validator->{checks}};
  print STDERR "<<< \n";

  for my $check (keys %checks){
    print STDERR "$check $checks{$check}>> ",$req,"\n";
    #print STDERR "TODO refaddr ",refaddr($checks{$check})," ",refaddr($req),"\n";
   # if{refaddr($checks{$check}) == refaddr($req)} {
      print " ";
      #$required{$_}=1 for (@{ref($check) eq 'ARRAY' ? $check : [$check]});
   # }

  }

  for my $field (@{$validator->{fields}}){
    # TODO dont fix if not required

    $params->{$field}=undef if not exists $params->{$field} and exists $required{$field};
    print STDERR "$field $params->{$field}\n";
  }
}
=cut
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

sub to_hash {
  my $delim = shift;
  my $pattern = shift;  
  sub {
    my $text = shift;
    my %h = map {m/$pattern/ ? ($1=>$2) : ('ERROR'=>undef)} split($delim,$text);
    return undef if exists($h{'ERROR'}) and not defined($h{'ERROR'});
    return \%h;
  }  
}
sub to_array_of_hash {
  my $fields = shift;
  my $delim = shift;
  my $pattern = shift;
  sub {
    my $text = shift;
    my @a = map { my @matched = m/$pattern/;
                  (@matched and @matched == @$fields) 
                                 ? ({map {$fields->[$_] => $matched[$_]} [0..$#$fields]}) 
                                 : (undef)
                } split($delim,$text);
    return undef if first {not defined($_)} @a;
    return \@a;
  }  
}

sub encrypt_text {
  my ($salt, $options) = @_;
  $options ||= {};

  my $cost = exists $options->{cost}    ? $options->{cost}    : 8;
  my $nul  = exists $options->{key_nul} ? $options->{key_nul} : 1;

  $nul = $nul ? 'a' : '';
  $cost = sprintf("%02i", 0+$cost);
  if ($salt) {
    my $l = length $salt;
    $l = (int($l / 8)+1)*8 if $l % 8;
    $salt = sprintf("%${l}s", $salt);
  } else {
    $salt = join('', map { chr(int(rand(256))) } 1 .. 16) unless $salt;
  }

  my $settings_str = join('','$2',$nul,'$',$cost, '$', Crypt::Eksblowfish::Bcrypt::en_base64($salt));

  sub {
    my $plain_text = shift;

    $plain_text = encode_utf8($plain_text) if is_utf8($plain_text); #  Bcrypt expects octets
    Crypt::Eksblowfish::Bcrypt::bcrypt($plain_text, $settings_str);
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

sub is_hash {
  my $error = shift;
  sub {
    my $h = shift;
    ($h and ref($h) eq 'HASH') ? undef : $error
  }
}

sub is_array_of_hash {
  my $error = shift;
  sub {
    my $a = shift;
    ($a and ref($a) eq 'ARRAY' and all {$_ and ref($_) eq 'HASH'} @$a) ? undef : $error
  }
}
1;
