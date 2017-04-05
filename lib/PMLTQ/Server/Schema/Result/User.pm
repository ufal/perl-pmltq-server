package PMLTQ::Server::Schema::Result::User;

use Mojo::Base qw/PMLTQ::Server::Schema::Result/;

__PACKAGE__->table('users');

__PACKAGE__->load_components('EncodedColumn', 'InflateColumn::DateTime', 'TimeStamp');

__PACKAGE__->add_columns(
  id               => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
  persistent_token => { data_type => 'varchar', is_nullable => 1, size => 250 },
  organization     => { data_type => 'varchar', is_nullable => 1, size => 250 },
  provider         => { data_type => 'varchar', is_nullable => 1, size => 250 },
  name             => { data_type => 'varchar', is_nullable => 1, size => 120 },
  username         => { data_type => 'varchar', is_nullable => 1, size => 120 },
  email            => { data_type => 'varchar', is_nullable => 1, size => 120 },
  password => {
    data_type => 'varchar', # hashes are 59-60 chars long - backward compatibility to Bcrypt key_nul=1 option !!!
    size => 60,
    is_nullable => 1,
    encode_column => 1,
    encode_class  => 'Crypt::Eksblowfish::Bcrypt',
    encode_args   => { key_nul => 0, cost => 8 },
    encode_check_method => 'check_password',
    is_serializable => 0
  },
  access_all       => { data_type => 'boolean', default_value => 0, is_nullable => 0, is_boolean => 1 },
  is_admin         => { data_type => 'boolean', default_value => 0, is_nullable => 0, is_boolean => 1 },
  is_active        => { data_type => 'boolean', default_value => 0, is_nullable => 0, is_boolean => 1 },
  created_at       => { data_type => 'datetime', is_nullable => 0, set_on_create => 1, set_on_update => 0 },
  last_login       => { data_type => 'datetime', is_nullable => 1, set_on_create => 1, set_on_update => 1 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint('user_username_unique', ['name']);

__PACKAGE__->has_many(
  user_treebanks => 'PMLTQ::Server::Schema::Result::UserTreebank',
  { 'foreign.user_id' => 'self.id' },
  { cascade_copy => 0, cascade_delete => 1 },
);

__PACKAGE__->many_to_many( available_treebanks => 'user_treebanks', 'treebank' );

__PACKAGE__->has_many(
  user_tags => 'PMLTQ::Server::Schema::Result::UserTag',
  { 'foreign.user_id' => 'self.id' },
  { cascade_copy => 0, cascade_delete => 1 },
);

__PACKAGE__->many_to_many( available_tags => 'user_tags', 'tag' );

__PACKAGE__->has_many(
  query_records => 'PMLTQ::Server::Schema::Result::QueryRecord',
  { 'foreign.user_id' => 'self.id' },
  { cascade_copy => 0, cascade_delete => 1 },
);

__PACKAGE__->has_many(
  query_files => 'PMLTQ::Server::Schema::Result::QueryFile',
  { 'foreign.user_id' => 'self.id' },
  { cascade_copy => 0, cascade_delete => 1 },
);

sub sqlt_deploy_hook {
  my ($self, $sqlt_table) = @_;

  $sqlt_table->add_index(name => 'idx_name', fields => ['username']);
  $sqlt_table->add_index(name => 'idx_external', fields => [qw/persistent_token organization provider/]);
}

sub new {
  my ( $self, $attrs ) = @_;

  if ($attrs->{provider}) {
    $attrs->{is_active} = 1;
  }

  $attrs->{is_active} = 0 unless defined($attrs->{is_active});
  $attrs->{is_admin} = 0;

  my $new = $self->next::method($attrs);

  return $new;
}

sub can_access_treebank {
  my ($self, $treebank_id, $tag_ids) = @_;
  my %tags = map {$_->id=>1} @{$tag_ids//[]};
  return 1 if $self->access_all; # user can access all treebanks
  return 1 if $self->user_treebanks->search({treebank_id => $treebank_id})->count; # available nonfree treebanks for current user
  return 1 if grep {exists $tags{$_->tag_id}} $self->user_tags->search(undef, {columns => [qw/tag_id/]}); # treeank and user has the same tag
  return 0;
}

sub mail {
  my $self = shift;
  my $template = shift;
  my $subject = $template->{subject};
  my $text = $template-> {text};
  my %args = (@_, 'NAME' => $self->name, 'USERNAME' => $self->username, 'EMAIL' => $self->email, 'PASSWORD' => $self->password) ;
  $text =~ s/%%(.*?)%%/$args{"$1"}||"%%$1%%"/ge;  ## if $1 is not in %args %%$1%% is not substituted
  return  {
      to => $self->email,
      subject => $subject,
      text => $text
    }
}

sub TO_JSON {
   my $self = shift;

   return {
      # $self->to_json_key('treebanks') => [map { $_->treebank_id } $self->available_treebanks->search(undef, {columns => [qw/treebank_id/]})],
      # $self->to_json_key('available_tags') => [map { $_->tag_id } $self->available_tags->search(undef, {columns => [qw/tag_id/]})],
      (map { ($self->to_json_key($_) => [$self->$_]) } qw/available_treebanks available_tags/),
      %{ $self->next::method },
   }
}

# sub get_last_login {
#   my $self = shift;
#   my $pattern = shift//'%Y-%m-%d %R';

#   my $last_login = $self->last_login;

#   $last_login = DateTime::Format::Strptime->new(
#     pattern => '%Y-%m-%dT%H:%M:%S',
#     time_zone => 'local'
#   )->parse_datetime($last_login) unless ref $last_login && $last_login->isa('DateTime');

#   return 'never' unless $last_login;

#   return $last_login->strftime($pattern);
# }

# sub logged {
#   my $self = shift;
#   $self->patch({last_login => DateTime->now()}, sub {my($user, $err) = @_;});
# }

sub history {
  my $self = shift;
  my $history = $self->query_files->single({name => 'HISTORY'});
  return $history;
}

1;
