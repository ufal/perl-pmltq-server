#!/usr/bin/env perl

use Mojolicious::Lite;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Crypt::Digest::SHA512;
use Crypt::JWT;


my $port = shift(@ARGV);
my $code = shift(@ARGV); # exchange code

my $secret_file = shift(@ARGV); #
my $client_id = shift(@ARGV);


sub calculate_secret {return Crypt::Digest::SHA512->new->add(shift)->addfile($secret_file)->hexdigest();}


my %grant_types = map {$_ => 1} qw/authorization_code refresh_token/;

my $expected_client_secret = calculate_secret($code);
my $expected_refresh_token;
my $treebank_list = [];

die 'I have no port!' unless $port;
die 'I have no code!' unless $code;
die 'I have no secret file!' unless ($secret_file and -e $secret_file);
die 'I have no client_id!' unless $client_id;

post '/config_server' => sub {
  my $c = shift;
  $treebank_list = $c->req->json('/treebanks');
  $c->render(json=>$c->req->json());
};

post '/token' => sub {
  my $c = shift;


  my $client_id2 = $c->req->param('client_id');
  $c->render(status => 400, text => 'client_id parameter is missing') unless $client_id2;
  $c->render(status => 400, text => 'invalid client_id value') unless $client_id2 eq $client_id;

  my $grant_type = $c->req->param('grant_type');
  $c->render(status => 400, text => 'grant_type parameter is missing') unless $grant_type;
  $c->render(status => 400, text => 'invalid grant_type value') unless exists $grant_types{grant_type};

  if($grant_type eq 'authorization_code'){
    my $code2 = $c->req->param('code');
    $c->render(status => 400, text => 'code parameter is missing') unless $code2;
    $c->render(status => 400, text => 'invalid code value') unless $code2 eq $code;
    render_jwt($c, get_jwt($c,$code));
  } elsif ($grant_type eq 'refresh_token'){
      my $refresh_token = $c->req->param('refresh_token');
      $c->render(status => 400, text => 'code parameter is missing') unless $refresh_token;
      $c->render(status => 400, text => 'invalid refresh_token value') unless $refresh_token eq $expected_refresh_token;
      render_jwt($c, get_jwt($c,$refresh_token));

  } else {
    $c->render(status => 500, text => 'unexpected test server error');
  }

};


post '/broken_token' => sub {
  my $c = shift;
  render_jwt($c, 'ERROR'.get_jwt($c,$code));
};

my $stop;

$SIG{TERM} = sub { Mojo::IOLoop->stop; exit(0) };

# Connect application with web server and start accepting connections
my $daemon
  = Mojo::Server::Daemon->new(app => app, listen => ["http://*:$port"]);
$daemon->start;

# Test is going to catch this message
say STDERR "Server is running";

# Call "one_tick" repeatedly from the alien environment
Mojo::IOLoop->start;


sub get_jwt {
  my $c = shift;
  my $new_client_secret = calculate_secret(shift);
  $c->render(status => 400, text => 'invalid refresh_token value') unless $new_client_secret eq $expected_client_secret;
  $expected_client_secret = $new_client_secret;

  open my $fh, "<", $secret_file  or die "could not open file: $!";
  my $key=<$fh>;
  close($fh);
  $expected_refresh_token = join('', map{('a'..'z','A'..'Z',0..9)[rand 62]} 0..32);
  return Crypt::JWT::encode_jwt(payload=>{
                                              corpora => $treebank_list,
                                              refresh_token => $expected_refresh_token,
                                              scope => 'read'
                                              },
                                alg=>'HS256',
                                key=>$key,
                                auto_iat => 1,
                                relative_exp => 30,
                                relative_nbf => 0
                                );
}


sub render_jwt {
  my $c = shift;
  my $jwt_data = shift;
  $c->render(status=>200,
             content_type => 'application/jwt',
             data => $jwt_data);
}

