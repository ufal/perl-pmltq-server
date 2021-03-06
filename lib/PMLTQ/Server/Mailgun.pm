package PMLTQ::Server::Mailgun;

use Mojo::Base 'Mojolicious::Plugin';
use WWW::Mailgun;

our $VERSION = '0.01';

sub register {
  my ($self, $app, $conf) = @_;
  $conf ||= {};
  my $mail_send;

  unless((exists $conf->{driver} and $conf->{driver} eq 'test') or exists $ENV{MOJO_MAIL_TEST}) {
    warn __PACKAGE__ . ': key is not defined' unless exists $conf->{key};
    warn __PACKAGE__ . ': domain is not defined' unless exists $conf->{domain};
    return unless $conf->{key} && $conf->{domain};
    $mail_send = WWW::Mailgun->new($conf);
  }


  $app->helper(
    mail => sub {
      ## TODO: sended mail counter (per day/per month)\
      return unless ($mail_send);
      my $self = shift;
      my %params;
      if (@_ % 2 == 0) {
          %params = @_;
      } else {
          die "Invalid params passed to mail helper!";
      }
      return $mail_send->send(\%params) if $mail_send;
      my $text = $params{html} // $params{text};
      $text =~ s/\s+/ /g;
      $self->app->log->info("[MAIL] To: $params{to},Subject: $params{subject},Body: $text");
    }
  );
}

1;
