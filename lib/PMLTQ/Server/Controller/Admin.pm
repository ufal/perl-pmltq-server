package PMLTQ::Server::Controller::Admin;
use Mojo::Base 'Mojolicious::Controller';

use utf8;
use Unicode::Normalize;
use Encode;
sub welcome {
  my $c = shift;
  $c->render(template => 'admin/welcome');
}
sub testuserexist {
  my $self = shift;
  my $username = $self->param('username');
#  print STDERR "testuserexist !!!\n\t$username\n";
  my $u = $self->pmltquser($username);
  $self->rendered($u ? 400 : 200);
}
sub adduser {
  my $self = shift;
  my $username = $self->param('username');
  $username= $self->generate_username($self->param('name')) unless $username;
  my $pass = $self->param('pass');
  unless($pass){
    $pass = generate_pass(10);
    # todo send generated pass via email
  }
#  print STDERR " TODO send pass via email if does not exists !!!\n";
#  print STDERR join(" ",map {$_->{'name'}}  @{$self->treebanks->find->all}),"\n";
#  print STDERR join(" ",$self->param),"\n";

  my %treebanks = map {$_->{'name'}=>1} grep {$self->param($_->{'name'})}  @{$self->treebanks->find->all};
#  print STDERR "TREEBANKS: ",join(" ",keys(%treebanks)),"\n";
  my %privs = map {$_=>1} grep {$self->param($_)}  qw/admin selfupdate/;
#  print STDERR "PRIVS:  ",join(" ",keys(%privs)),"\n";
  my $user = {name=>$self->param('name'),
              username=>$username,
              pass=>$pass,
              email=>$self->param('email'),
              $self->param('active')?(active=>1):(active=>0),
              treebanks=>\%treebanks,
              privs=>\%privs};
  $self->flash(err => 'user already exists !!!') unless $self->app->adduser($user);
  $self->redirect_to("/admin/user/list");
}



sub deluser {
  my $self = shift;
  $self->flash(err => 'user does not exist') unless $self->app->deluser($self->param('username'));
  $self->redirect_to("/admin/user/list");
}

sub updateuser {
  my $self = shift;
  my $user = $self->pmltquser($self->param('username'));
  my %treebanks = map {$_->{'name'}=>1} grep {$self->param($_->{'name'})}  @{$self->treebanks->find->all};
  my %privs = map {$_=>1} grep {$self->param($_)}  qw/admin selfupdate/;
  $user->{'pass'} = $self->param('pass') if $self->param('pass');
  $user->{'treebanks'} = \%treebanks;
  $user->{'privs'} = \%privs;
  $user->{'email'} = $self->param('email');
  $self->app->updateuser($self->param('username'),$user);
  $self->redirect_to("/admin/user/list");
}



sub adduser_form{
  my $self = shift;
 # print STDERR "ADD USER\n";
 # $self->render('admin/user_form');
  $self->render('admin/user_form');
}


sub updateuser_form{
  my $self = shift;
 # print STDERR "UPDATE USER\n";
  $self->render('admin/user_form');
}


sub addtreebank {
  my $self = shift;
  $self->flash(err => 'treebank already exists !!!') unless $self->app->addtreebank({name=>$self->param('name'),visible=>$self->param('visible'),public=>$self->param('public'),anonaccess=>$self->param('anonaccess')});
  $self->redirect_to("/admin/treebank/list");
}


sub deltreebank {
  my $self = shift;
  $self->flash(err => 'user does not exist') unless $self->app->deltreebank($self->param('username'));

  $self->redirect_to("/admin/treebank/list");
}
sub updatetreebank {
  my $self = shift;
  $self->flash(err => 'TODO: updatetreebank');
  $self->redirect_to("/admin/treebank/list");
}


sub generate_username
{
  my $self = shift;
  my $str = shift;
  use Lingua::Translit;
  my $tr = new Lingua::Translit("ISO 843"); # greek
  $str = $tr->translit($str);
  $tr = new Lingua::Translit("ISO 9"); # Cyrillic
  $str = $tr->translit($str);
  #  $str = decode("utf8", $str);
  $str = NFD($str);
  $str =~ s/\pM//og;
  $str =~ tr/A-Z /a-z./;
  $str =~ s/[^A-Za-z0-9\.]//g;

  $str =~ s/^\.*//;
  $str =~ s/\.*$//;
  $str =~ s/\.+/\./;
  my $append="";
  while($self->pmltquser("$str$append")){
    $append=0 unless $append;
    $append++;
  }
  return "$str$append";
}

sub generate_pass
{
  my $len=shift;
  my $i=$len;
  my $a;
  my $pass="";
  while($i){
    my $r = int(rand(2));
    if($pass =~ m/[a-z][a-z]$/ and $r){
      $a =  chr(int(rand( ord('Z')-ord('A')+1 )) + ord('A')) ;
    } elsif ($pass =~ m/[a-zA-Z]{4}$/ or $pass=~ m/[^0-9][0-9]$/) {
      $a=int(rand(10));
    } elsif($pass =~ m/[^aeiouy0-9]$/ and not($pass) ) {
      $a =  substr("aeiouy",int(rand(6)),1) ;
    } else {
      $a =  chr(int(rand( ord('z')-ord('a')+1 )) + ord('a')) ;
    }

    $pass.=  $a;
    $i--;
  }
  return $pass;
}


1;
