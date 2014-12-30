package Mojolicious::Plugin::Mailgun;

use Mojo::Base 'Mojolicious::Plugin';
use WWW::Mailgun;

our $VERSION = '0.01';

sub register {
  my ($self, $app, $conf) = @_;
  $conf ||= {};
  my $mail_send;
  unless((exists $conf->{driver} and $conf->{driver} eq 'test') or exists $ENV{MOJO_MAIL_TEST}) {
    die __PACKAGE__ . ': key is not defined' unless exists $conf->{key};
    die __PACKAGE__ . ': domain is not defined' unless exists $conf->{domain};
    $mail_send = WWW::Mailgun->new($conf);
  }
  

  $app->helper(
    mail => sub {
      my $self = shift;
      my %params;
      if (@_ % 2 == 0) {
          %params = @_;
      } else {
          die "Invalid params passed to mail helper!";
      }
      return $mail_send->send(\%params) if $mail_send;
      my $text = $params{html} // $params{text};
      $text =~ s/\s*/ /g;
      $self->app->log->debug("To: $params{to},Subject: $params{subject},Body: $text");
    }
  );
}

1;
