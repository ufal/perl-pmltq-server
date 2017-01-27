package PMLTQ::Server::Controller::Admin::User;

# ABSTRACT: Managing users in administration

use Mojo::Base 'PMLTQ::Server::Controller::CRUD';
use PMLTQ::Server::Validation;

has resultset_name => 'User';

has search_fields => sub { [qw/name username email/] };

sub _validate {
  my ($c, $user_data) = @_;

  my $rules = {
    fields => [qw/name username password email is_active is_admin access_all available_treebanks available_tags/],
    filters => [
      # Remove spaces from all
      [qw/name username email/] => filter(qw/trim strip/),
      [qw/is_active is_admin access_all/] => force_bool(),
    ],
    checks => [
      [qw/name username password email/] => is_long_at_most(120),
      username => is_unique($c->resultset, 'id', 'username already exists'),
      email => is_valid_email(),
      available_treebanks => is_array("invalid treebank list format"),
      available_tags => is_array("invalid tag list format")
    ]
  };

  return $c->do_validation($rules, $user_data);
}

1;

# use Mojo::Base 'Mojolicious::Controller';
# use Mango::BSON 'bson_oid';
# use List::Util qw(first all);
# use Lingua::Translit;
# use Unicode::Normalize;
# use PMLTQ::Server::Validation;
# use DateTime;
# use Mojo::JSON;

# use PMLTQ::Server::Model::Sticker ();
# use PMLTQ::Server::Model::Permission ();
# use PMLTQ::Server::Model::Treebank ();

# =head1 METHODS

# =head2 list

# List all users in the database

# =cut

# sub list {
#   my $c = shift;

#   $c->mandel->collection('user')->all(sub {
#     my($collection, $err, $users) = @_;

#     $c->flash(error => "Database Error: $err") if $err;

#     $c->stash(users => $users);
#     $c->render(template => 'admin/users/list');
#   });

#   $c->render_later;
# }

# sub new_user {
#   my $c = shift;
#   $c->stash(user => $c->mandel->collection('user')->create($c->app->config->{model}->{user}||{}));
#   $c->render(template => 'admin/users/form');
# }

# sub new_users {
#   my $c = shift;
#   $c->render(template => 'admin/users/massform');
# }


# sub create {
#   my $c = shift;

#   if ( my $user_data = $c->_validate_user($c->param('user')) ) {
#     my $users = $c->mandel->collection('user');
#     my $user = $users->create($user_data);

#     $user->save(sub {
#       my ($user, $err) = @_;
#       if ($err) {
#         $c->flash(error => "Database Error: $err");
#         $c->stash(user => $user);
#         $c->render(template => 'admin/users/form');
#       } else {
#         $c->redirect_to('show_user', id => $user->id);
#       }
#     });

#     $c->render_later;
#   } else {
#     $c->flash(error => "Can't save invalid user");
#     $c->render(template => 'admin/users/form', status => 400);
#   }
# }

# sub masscreate {
#   my $c = shift;
#   my @userIdents = map {[split(";",$_)]} grep {$_} split("\n",  $c->param('user')->{'users'});

#   if($c->param('sticker')
#      and $c->param('sticker')->{'name'}
#      and $c->mandel->collection('sticker')->search({name => $c->param('sticker')->{'name'}})->count) {
#     $c->flash(error => "Sticker ".$c->param('sticker')->{'name'}." already exists");
#     $c->render(template => 'admin/users/massform', status => 400);
#     return;
#   }

#   my $sticker = PMLTQ::Server::Model::Sticker::create_sticker($c,$c->param('sticker'));
#   if($sticker) {
#     $sticker->save(sub {
#       my ($sticker, $err) = @_;
#       if ($err) {
#         $c->flash(error => "Database Error: $err");
#       }
#     });
#     my $id = $sticker->id;
#     $c->param('user')->{'stickers'} = $c->param('user')->{'stickers'} ? $c->param('user')->{'stickers'}.",$id" : $id;
#   }

#   my $users = $c->mandel->collection('user');
#   my @addusers;
#   my %bannednames;
#   my $ok = 1;
#   if(@userIdents and all {$#$_ +1  == 2} @userIdents) {
#     delete $c->param('user')->{'users'};
#     for my $u (@userIdents) {
#       my ($name,$email) = @$u;
#       my $username = $c->generate_username($name,\%bannednames);
#       my $password = $c->generate_pass(10);
#       if ( my $user_data = $c->_validate_user({ %{$c->param('user')},
#                                                 name => $name,
#                                                 email => $email,
#                                                 username => $username,
#                                                 password => $password,
#                                                 password_confirm => $password}) ) {
#         push @addusers,[$users->create($user_data),$password];
#       } else {
#         $ok = 0;
#         $c->flash(error => "Can't save invalid users");
#         $c->render(template => 'admin/users/massform', status => 400);
#         last;
#       }
#     }
#   } else {
#     $ok = 0;
#     $c->flash(error => "Can't save invalid users");
#     $c->render(template => 'admin/users/massform', status => 400);
#   }
#   if($ok) {
#     my @notadded;

#     for my $u (@addusers) {
#       my ($user,$password) = @$u;
#       $user->save(sub {
#         my ($user, $err) = @_;
#         if ($err) {
#           push @notadded,[$user,$err];
#         } else {
#           $c->app->mail(%{$user->mail($c->app->config->{mail_templates}->{registration},
#                                       HOME => $c->app->url_for('home'),
#                                       PLAIN_PASSWORD => $password)
#                          });
#         }
#       });
#     }
#     if(@notadded) {
#       $c->flash(error => "Database Error");
#       $c->render(template => 'admin/users/massform', status => 400);
#     } else {
#       $c->redirect_to('list_users');
#       $c->render_later;
#     }
#   }
# }

# sub find_user {
#   my $c = shift;
#   my $user_id = $c->param('id');

#   $c->mandel->collection('user')->search({_id => bson_oid($user_id)})->single(sub {
#     my($users, $err, $user) = @_;

#     if ($err) {
#       $c->flash(error => "$err");
#       $c->render_not_found;
#       return 0;
#     }

#     $c->stash(user => $user);
#     $c->continue;
#   });

#   return undef;
# }

# sub show {
#   my $c = shift;
#   $c->render(template => 'admin/users/form');
# }

# sub update {
#   my $c = shift;
#   my $user = $c->stash->{user};

#   if ( my $user_data = $c->_validate_user($c->param('user'), $user) ) {
#     $user->patch($user_data, sub {
#       my($user, $err) = @_;

#       $c->flash(error => "$err") if $err;
#       $c->stash(user => $user);
#       $c->render(template => 'admin/users/form');
#     });

#     $c->render_later;
#   } else {
#     $c->flash(error => "Can't save invalid user");
#     $c->render(template => 'admin/users/form', status => 400);
#   }
# }

# sub remove {
#   my $c = shift;
#   my $user = $c->stash->{user};

#   $user->remove(sub {
#     my($user, $err) = @_;

#     if ($err) {
#       $c->flash(error => "$err");
#       $c->stash(user => $user);
#       $c->render(template => 'admin/users/form');
#     } else {
#       $c->redirect_to('list_users');
#     }
#   });

#   $c->render_later;
# }

# sub _validate_user {
#   my ($c, $user_data, $user) = @_;

#   $user_data ||= {};

#   $user_data = {
#     available_treebanks => [],
#     permissions => [],
#     stickers => "",
#     is_active => Mojo::JSON->false,
#     %$user_data
#   };
#   my $rules = {
#     fields => [qw/name username password password_confirm email is_active available_treebanks permissions last_login/],
#     filters => [
#       # Remove spaces from all
#       [qw/name username email/] => filter(qw/trim strip/),
#       ($user_data->{password} ? (password => encrypt_password()) : ()),
#       is_active => force_bool(),
#       available_treebanks => list_of_dbrefs(PMLTQ::Server::Model::Treebank->model->collection_name),
#       permissions => list_of_dbrefs(PMLTQ::Server::Model::Permission->model->collection_name),
#       stickers => [sub {return [split(',',shift)]},list_of_dbrefs(PMLTQ::Server::Model::Sticker->model->collection_name)]
#     ],
#     checks => [
#       [qw/name username password password_confirm email/] => is_long_at_most(200),
#       username => [is_required(), sub {
#         my $username = shift;
#         my $count = $c->mandel->collection('user')->search({
#           username => $username,
#           ($user ? (_id => { '$ne' => $user->id }) : ())
#         })->count;
#         return $count > 0 ? "Username '$username' already exists" : undef;
#       }],
#       [qw/password password_confirm/] => is_required_if(!$user),
#       password => is_password_equal(password_confirm => "Passwords don't match"),
#       email => is_valid_email(),
#     ]
#   };

#   $user_data = $c->do_validation($rules, $user_data);

#   return $user_data unless $user_data; # Fail if not valid

#   # Replace empty password if possible
#   unless ($user_data->{password}) {
#     $user_data->{password} = $user->password if $user;
#   }

#   return $user_data;
# }


# sub generate_username
# {
#   my $self = shift;
#   my $str = shift;
#   my $bannednames=shift;
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
#   while(@{$self->users->search({username => "$str$append"})->all} or ($bannednames and eval{exists($bannednames->{"$str$append"})})){
#     $append=0 unless $append;
#     $append++;
#   }
#   $bannednames->{"$str$append"}=1 if (defined($bannednames));
#   return "$str$append";
# }

# sub generate_pass
# {
#   my $self = shift;
#   my $len=shift;
#   my $i=$len;
#   my $a;
#   my $pass="";
#   while($i>0){
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

# 1;
