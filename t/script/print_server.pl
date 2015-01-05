#!/usr/bin/env perl

use Mojolicious::Lite;
use Mojo::IOLoop;
use Mojo::Server::Daemon;

my $port = shift(@ARGV);

die 'I have no port!' unless $port;

post '/svg' => sub {
	my $c = shift;

	$c->res->headers->content_type('image/svg+xml');
	$c->reply->static('svg_example.svg');
};

post '/svg_error' => sub {
	die 'Intentional error'
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

__DATA__

@@ svg_example.svg
<?xml version="1.0"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">

<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="120" height="120" viewBox="0 0 236 120">
  <rect x="14" y="23" width="200" height="7" fill="lime" stroke="black" stroke-width="1" />
</svg>
