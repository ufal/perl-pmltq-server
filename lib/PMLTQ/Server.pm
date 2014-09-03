package PMLTQ::Server;
use Mojo::Base 'Mojolicious';

use Mango;
use Mango::BSON ':bson';
use PMLTQ::Server::Model;


has db => sub { state $mango = Mango->new($ENV{PMLTQ_SERVER_TESTDB} || shift->config->{mongo_uri}) };

has mandel => sub {
  state $mandel = PMLTQ::Server::Model->new(
    storage => shift->db,
    #model_class => 'PMLTQ::Server::Model',
    namespaces => [qw/PMLTQ::Server::Model/])
};

# This method will run once at server start
sub startup {
  my $self = shift;

  $self->plugin('Config' => {
    file => $self->home->rel_file('config/pmltq_server.conf')
  });
  $self->plugin("PMLTQ::Server::Helpers");
  $self->plugin("bootstrap3");
  $self->plugin(Charset => {charset => 'utf8'});
  $self->plugin('authentication' => {
          'autoload_user' => 0,
          'session_key' => 'auth_data',
          'our_stash_key' => 'auth',
          'load_user' => sub { 
                 my ($app, $uid) = @_; 
                 print STDERR "load_user \t$uid \n",$self->pmltquser($uid),"\n";
                 return $self->pmltquser($uid);
               },
          'validate_user' =>  sub {
                 my ($app, $username, $password, $extradata) = @_;
                 my $user = $self->pmltquser($username);
                 return undef unless $user;
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
  
  
  # Show log in STDERR
  $self->log->handle(\*STDERR);

  # Setup all helpers
  # $self->setup_helpers(); ###  moved to PMLTQ::Server::Helpers

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('Auth#login');
  $r->post('/')->to('Auth#check');  
  $r->get('/logout')->to('Auth#pmltq_logout');
  $r->get('/admin')->over(authenticated => 1, has_priv => 'admin')->to('Admin#welcome');
  
  
  
  $r->get('/admin/user/test')       ->over(authenticated => 1, has_priv => 'admin')     ->to('Admin#testuserexist');
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
  
  my $treebank = $r->bridge('/:treebank')->
    name('treebank')->to(controller => 'Treebank', action => 'initialize');
  $treebank->get ('metadata')->to('#metadata');
  $treebank->post('suggest')->to('#suggest');
  $treebank->get ('history')->to(controller => 'History', action => 'list');
  $treebank->post('query')->to(controller => 'Query', action => 'query');
  $treebank->post('query/svg', 'query_svg')->to(controller => 'Query', action => 'query_svg');
  $treebank->post('svg')->to(controller => 'Query', action => 'result_svg');
}





1;
