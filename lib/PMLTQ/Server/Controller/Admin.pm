package PMLTQ::Server::Controller::Admin;

use Mojo::Base 'Mojolicious::Controller';

sub welcome {
  my $c = shift;
  $c->render(template => 'admin/welcome');
}

# sub generate_username
# {
#   my $self = shift;
#   my $str = shift;
#   # use Lingua::Translit;
#   my $tr = new Lingua::Translit("ISO 843"); # greek
#   $str = $tr->translit($str);
#   $tr = new Lingua::Translit("ISO 9"); # Cyrillic
#   $str = $tr->translit($str);
#   #  $str = decode("utf8", $str);
#   $str = NFD($str);
#   $str =~ s/\pM//og;
#   $str =~ tr/A-Z /a-z./;
#   $str =~ s/[^A-Za-z0-9\.]//g;

#   $str =~ s/^\.*//;
#   $str =~ s/\.*$//;
#   $str =~ s/\.+/\./;
#   my $append="";
#   while($self->pmltquser("$str$append")){
#     $append=0 unless $append;
#     $append++;
#   }
#   return "$str$append";
# }

# sub generate_pass
# {
#   my $len=shift;
#   my $i=$len;
#   my $a;
#   my $pass="";
#   while($i){
#     my $r = int(rand(2));
#     if($pass =~ m/[a-z][a-z]$/ and $r){
#       $a =  chr(int(rand( ord('Z')-ord('A')+1 )) + ord('A')) ;
#     } elsif ($pass =~ m/[a-zA-Z]{4}$/ or $pass=~ m/[^0-9][0-9]$/) {
#       $a=int(rand(10));
#     } elsif($pass =~ m/[^aeiouy0-9]$/ and not($pass) ) {
#       $a =  substr("aeiouy",int(rand(6)),1) ;
#     } else {
#       $a =  chr(int(rand( ord('z')-ord('a')+1 )) + ord('a')) ;
#     }

#     $pass.=  $a;
#     $i--;
#   }
#   return $pass;
# }


1;
