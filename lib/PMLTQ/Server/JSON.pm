package PMLTQ::Server::JSON;

use Mojo::Base -strict;
use String::CamelSnakeKebab qw/lower_camel_case lower_snake_case/;
use Encode qw(is_utf8 encode_utf8);
use Exporter 'import';
use Memoize;

BEGIN {
  memoize('lower_camel_case', INSTALL => 'json_key');
  memoize('lower_snake_case', INSTALL => 'perl_key');
}

our @EXPORT_OK = qw/json json_key perl_key/;
our @EXPORT = qw/json/;

sub json {
  my $hash = shift;
  die "$hash is not a hashref" unless ref $hash eq 'HASH';
  return bless($hash, 'PMLTQ::Server::JSON::_Object');
}

package PMLTQ::Server::JSON::_Object;

sub TO_JSON {
  my $self = shift;
  return {
    map +(PMLTQ::Server::JSON::json_key($_) => $self->{$_}), keys %$self
  }
}

1;
