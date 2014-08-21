package PMLTQ::Server;
use Mojo::Base 'Mojolicious';

use Mango;
use Mango::BSON ':bson';


has db => sub { state $mango = Mango->new(shift->config->{mongo_uri}) };

# This method will run once at server start
sub startup {
  my $self = shift;

  $self->plugin('Config' => {
    file => $self->home->rel_file('config/pmltq_server.conf')
  });
  $self->plugin("bootstrap3");
  $self->plugin(Charset => {charset => 'utf8'});
  $self->plugin('authentication' => {
          'autoload_user' => 0,
          'session_key' => 'auth_data',
          'our_stash_key' => 'auth',
          'load_user' => sub { 
                 my ($app, $uid) = @_; 
                 print STDERR "load_user \t$uid \n",$self->user($uid),"\n";
                 
                 return $self->user($uid);
                 
                 #return {name=>"pmltq",pass=>"q"} if $uid eq 'pmltq'; 
                 #return {name=>"pmltq2",pass=>"q"} if $uid eq 'pmltq2'; 
               },
          'validate_user' =>  sub {
                 my ($app, $username, $password, $extradata) = @_;
                 #my $uid = 'userid';
                 #return $uid if ($username eq 'pmltq' and $password eq 'q');
                 print STDERR "validate_user\t$username\t$password \n";
                 
                 my $user = $self->user($username);
                 return undef unless $user;
                 print STDERR $user->{'username'} ," ",$user->{'pass'} eq $password," ",$user->{'active'};
                 return $username if $user->{'pass'} eq $password && $user->{'active'};
                 
               },
          'current_user_fn' => 'current_user', # compatibility with old code
         });
  $self->plugin('Authorization' => {
          'has_priv'   => sub { 
                 my $self = shift;
                 my $privname = shift;
                 return 1 if $self->current_user->{'privs'}->{$privname} || $self->current_user->{'privs'}->{'admin'};        
                 return 0;
               },
          'is_role'    => sub { print STDERR 'TODO: is_role\n'; },
          'user_privs' => sub { print STDERR 'TODO: user_privs\n'; },
          'user_role'  => sub { print STDERR 'TODO: user_role\n'; },
         });
  setup_helpers($self);
  
  

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('Auth#login');
  $r->post('/')->to('Auth#check');  
  $r->get('/logout')->to('Auth#pmltq_logout');
  $r->get('/admin')->over(authenticated => 1, has_priv => 'admin')->to('Admin#welcome');
  
  
  
  $r->get('/admin/user/list')       ->over(authenticated => 1, has_priv => 'admin')     ->to('Admin#listuser');
  $r->post('/admin/user/add')       ->over(authenticated => 1, has_priv => 'admin')     ->to('Admin#adduser');
  $r->get('/admin/user/add')        ->over(authenticated => 1, has_priv => 'admin')     ->to('Admin#adduser_form');
  $r->get('/admin/user/delete')     ->over(authenticated => 1, has_priv => 'admin')     ->to('Admin#deluser'); 
  $r->post('/admin/user/update')    ->over(authenticated => 1, has_priv => 'admin')     ->to('Admin#updateuser');
  $r->get('/admin/user/update')     ->over(authenticated => 1, has_priv => 'admin')     ->to('Admin#updateuser_form');
  
  $r->post('/profile/selfupdate')->over(authenticated => 1, has_priv => 'selfupdate')->to('Profile#update');
  $r->get('/profile/selfupdate') ->over(authenticated => 1, has_priv => 'selfupdate')->to('Admin#update_form');
  $r->get('/profile')            ->over(authenticated => 1)                          ->to('Profile#index');
 
  $r->get('/admin/treebank/list')    ->over(authenticated => 1, has_priv => 'admin')->to('Admin#listtreebank');
  $r->post('/admin/treebank/add')    ->over(authenticated => 1, has_priv => 'admin')->to('Admin#addtreebank');
  $r->get('/admin/treebank/add')     ->over(authenticated => 1, has_priv => 'admin')->to('Admin#addtreebank_form');
  $r->get('/admin/treebank/delete')  ->over(authenticated => 1, has_priv => 'admin')->to('Admin#deltreebank'); 
  $r->post('/admin/treebank/update') ->over(authenticated => 1, has_priv => 'admin')->to('Admin#updatetreebank'); 
  $r->get('/admin/treebank/update')  ->over(authenticated => 1, has_priv => 'admin')->to('Admin#updatetreebank_form'); 
  
  
  
  
  $r->get('/mongotest' => sub {
    my $c = shift;

    my $collection = $c->mango->db->collection('visitors');
    my $ip         = $c->tx->remote_address;

    # Store information about current visitor
    $collection->insert({when => bson_time, from => $ip} => sub {
      my ($collection, $err, $oid) = @_;

      return $c->render_exception($err) if $err;

      # Retrieve information about previous visitors
      $collection->find->sort({when => -1})->fields({_id => 0})->all(sub {
        my ($collection, $err, $docs) = @_;

        return $c->render_exception($err) if $err;

        # And show it to current visitor
        $c->render(json => $docs);
      });
    });

    $c->render_later;
  })
}


sub setup_helpers {
  my $self = shift;     
  $self->helper(mango       => sub { shift->app->db });
  # COLLECTIONS
  $self->helper(users       => sub { shift->app->mango->db->collection('users') });
  $self->helper(treebanks   => sub { shift->mango->db->collection('treebanks') });
  # ELEMENT IN COLLECTION
  $self->helper(user        => sub { my ($self,$username) = @_; 
                                     return $self->users->find_one({'username' => $username}) 
                                   });
  $self->helper(treebank    => sub { my ($self,$tbname) = @_; 
                                     return $self->treebanks->find_one({'name' => $tbname}) 
                                   });
  # ADD
  $self->helper(adduser     => sub { 
                                     #my ($self,$username,$password,$email,@treebanks) = @_; 
                                     #return 0 if $self->user($username);
                                     my ($self,$user) = @_;
                                     return 0 if $self->user($user->{'username'});
                                     $self->users->insert($user);
                                     return 1;
                                   });
  
  $self->helper(addtreebank => sub {  my ($self,$treebank) = @_;
                                     return 0 if $self->treebank($treebank->{'name'});
                                     $self->treebanks->insert($treebank);
                                     return 1;
                                   });
  # DELETE
  $self->helper(deluser     => sub { 
                                     my ($self,$username) = @_;
                                     return 0 unless $self->user($username);
                                     $self->users->remove({'username'=>$username});
                                     return 1;
                                   });
  $self->helper(deltreebank => sub { 
                                     my ($self,$tbname) = @_;
                                     return 0 unless $self->treebank($tbname);
                                     $self->treebanks->remove({'name'=>$tbname});
                                     return 1;
                                   });
  # UPDATE 
  $self->helper(updateuser     => sub { 
                                     my($self,$username,$data) = @_;
                                     
                                     #my $username = $d->{'username'};
                                     #my $data =  $d->{'data'};
                                     
                                     # probíhá update všeho !!! nelze projet cyklem, musíme si předem uložit ostatní údaje - nejlépe vytágnout usera z databáze, aktualizovat ho a pak ho nahrát do databáze
                                     my $user = $self->user($username);
                                     print STDERR "UPDATE: $user\n";
                                     print STDERR  "\tname=$username\n";
                                     print STDERR  "\tdata=$data\n";
                                     return 0 unless $user;
                                     
                                     
                                     $self->users->update({username=>$username},{$_=>$data->{$_}}) for (keys %$data);
                                     return 1;
                                   });
  
  
}

1;
