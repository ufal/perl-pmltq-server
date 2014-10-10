package PMLTQ::Server::FormHelpers;

# Based on FormFields plugin

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util 'xml_escape';
use Carp ();

sub register {
  my ($self, $app) = @_;
  my $ns = 'form-helpers';

  $app->helper(field => sub {
    my $c    = shift;
    my $name = shift || '';
    $c->stash->{$ns}->{$name} ||= PMLTQ::Server::FormHelpers::Field->new($c, $name, @_);
    $c->stash->{$ns}->{$name};
  });

  $app->helper(fields => sub {
    my $c    = shift;
    my $name = shift || '';
    $c->stash->{$ns}->{$name} ||= PMLTQ::Server::FormHelpers::ScopedField->new($c, $name, @_);
    $c->stash->{$ns}->{$name};
  });

  $app->helper(semantic_form_for => sub {
    my $c    = shift;
    my $name = shift;

    Carp::croak 'object name is required' unless $name;

    # Content
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $content = @_ % 2 ? pop : undef;

    my $value = $c->stash($name);
    my $is_edit = $c->current_route("update_$name") || $c->current_route("show_$name");
    my $url = $is_edit ? $c->url_for("update_$name", $value->id) : $c->url_for("create_$name");

    return $c->tag('form', action => $url, method => 'POST', @_, sub {
      my $form;
      $form .= $c->hidden_field(_method => 'PUT') if $is_edit;
      $form .= $cb->() if $cb;
      $form .= xml_escape($content) if $content;
      return $form;
    });
  });

  $app->helper(semantic_title => sub {
    my $c    = shift;
    my $name = shift;

    my $is_edit = $c->current_route("update_$name") || $c->current_route("show_$name");
    $c->stash(title => (($is_edit ? 'Edit ' : 'New ') . ucfirst $name));
  });
}

package PMLTQ::Server::FormHelpers::Field;

use Mojo::Base -strict;
use Scalar::Util;
use Mojo::Util 'xml_escape';
use Mojo::ByteStream;
use Carp ();

use overload
  '""'  => '_to_string',
  bool  => sub { 1 },
  fallback => 1;

my $SEPARATOR = '.';
our @TEXT_FIELD_TYPES = qw(color email number range search tel text url date datetime month time week);

for my $name (@TEXT_FIELD_TYPES) {
  my $field = "${name}_field";
  no strict 'refs';
  *$name = sub { shift->input($name, @_) };
  *$field = sub { shift->_form_field($name, @_)}
}

sub new {
  my $class = shift;
  my ($c, $name, $object) = @_;
  Carp::croak 'field name required' unless $name;

  my $self = bless {
    c       => $c,
    name    => $name,
    object  => $object,
    path    => [split /\Q$SEPARATOR/, $name],
  }, $class;

  Scalar::Util::weaken $self->{c};
  $self;
}

sub checkbox {
  my $self = shift;

  my $value;
  $value = shift if @_ % 2;
  $value //= 1;

  my %options = @_;
  $options{value} //= $value;

  $self->input('checkbox', %options);
}

sub checkbox_field { shift->_form_field('checkbox', @_) }

sub checkbox_options {
  my $self = shift;
  my %attrs = @_;
  my $options = delete $attrs{options};

  my $value = $self->_lookup_value;
  $value = [$value] if defined $value && ref $value ne 'ARRAY';
  $value = [] unless defined $value;

  # turn into hash map
  my %lookup = map { ($_ ? $_->id : $_) => 1 } @$value;

  my $content = Mojo::ByteStream->new;
  for my $option (keys %$options) {
    $$content .= $self->checkbox_field(
      $options->{$option},
      value => $option,
      ($lookup{$option} ? (checked => 'checked') : ())
    )
  }

  return $content;
}

sub file {
  my ($self, %options) = @_;
  $options{id} //= $self->_dom_id;

  $self->{c}->file_field($self->{name}, %options);
}

sub input {
  my ($self, $type, %options) = @_;
  my $value;
  $value = $self->_lookup_value unless $options{value};

  $options{id} //= $self->_dom_id;
  $options{value} //= $value if defined $value;
  $options{type} = $type;

  if($type eq 'checkbox' || $type eq 'radio') {
    $options{checked} = 'checked'
      if !exists $options{checked} && defined $value && $value eq $options{value};
  }

  $self->{c}->input_tag($self->{name}, %options);
}

sub hidden {
  my ($self, %options) = @_;
  $self->input('hidden', %options);
}

sub radio {
  my ($self, $value, %options) = @_;
  Carp::croak 'value required' unless defined $value;

  $options{id} //= $self->_dom_id($value);
  $options{value} = $value;

  $self->input('radio', %options);
}

sub radio_field { shift->_form_field('radio', @_) }

sub select {
  my $self = shift;
  my $options = @_ % 2 ? shift : [];
  my %attr = @_;
  $attr{id} //= $self->_dom_id;

  my $c = $self->{c};
  my $name = $self->{name};
  my $field;
  if (defined $c->param($name)) {
    $field = $c->select_field($name, $options, %attr);
  } else {
    # Make select_field select the value
    $c->param($name, $self->_lookup_value);
    $field = $c->select_field($name, $options, %attr);
    $c->param($name, undef);
  }

  $field;
}

sub select_option {
  my $self = shift;
  my %attrs = @_;
  $attrs{id} //= $self->_dom_id;
  $attrs{name} = $self->{name};
  my $options = delete $attrs{options};
  my $value = $self->_lookup_value;

  $self->{c}->tag('select', %attrs, sub {
    my $content = Mojo::ByteStream->new;
    for my $option (@$options) {
      $$content .= $self->{c}->tag('option',
        value => $option->[0],
        ($value eq $option->[0] ? (selected => 'selected') : ()),
        $option->[1]
      )
    }
    return $content
  });
}

sub select_option_field { shift->_form_field('select_option', @_) }

sub password {
  my ($self, %options) = @_;
  $options{id} //= $self->_dom_id;

  $self->{c}->password_field($self->{name}, %options);
}

sub password_field { shift->_form_field('password', @_) }

sub label {
  my $self = shift;

  my $text;
  $text = pop if ref $_[-1] eq 'CODE';
  $text = shift if @_ % 2;	# step on CODE
  $text //= $self->_default_label;

  my %options = @_;
  $options{for} //= $self->_dom_id;

  $self->{c}->tag('label', %options, $text)
}

sub textarea {
  my ($self, %options) = @_;
  $options{id} //= $self->_dom_id;

  my $size = delete $options{size};
  if($size && $size =~ /^(\d+)[xX](\d+)$/) {
    $options{rows} = $1;
    $options{cols} = $2;
  }
  my $fields = delete $options{show_fields};
  my $error = $self->{c}->validator_error($self->{path}->[-1]);
  $self->{c}->text_area($self->{name}, %options, sub {get_structured_data($self,$fields)} );
  my $label = $self->_default_label;
  $self->{c}->tag('div', class => ('form-group' . ($error ? ' has-error' : '')), sub {
      my $content = $self->label($label . ':');
      $content .= $self->{c}->text_area($self->{name}, %options, sub {get_structured_data($self,$fields)}); 
      $content .= $self->{c}->tag('p', class => 'text-danger', $error) if $error;
      return $content;
    });  
}

sub get_structured_data {
  my ($self,$fields)=@_; 
  my $val = $self->_lookup_value;
  return '' unless $val;
  return join("\n",map {"[$_]($val->{$_})"} keys %$val)if ref $val eq 'HASH';
  
  if(ref $val eq 'ARRAY') {
    return '' unless $fields;
    my ($k1,$k2) = @$fields;
    return join('\n',map {"[$_->{$k1}]($_->{$k2})"} @$val);
  }
  return $val;
}

sub each {
  my $self = shift;
  my $block = pop;
  my $fields = $self->_to_fields;

  return $fields unless ref($block) eq 'CODE';

  local $_;
  $block->() for @$fields;

  return;
}

sub separator { $SEPARATOR; }

sub _to_string { shift->_lookup_value; }

sub _dom_id {
  my $self = shift;
  my $value = '';
  $value = '-' . join('-', @_) if (@_ > 0);
  unless ($self->{dom_id}) {
    my @path = @{$self->{path}};
    s/[^\w]+/-/g for @path;
    $self->{dom_id} = join '-', @path;
  }
  return $self->{dom_id} . $value;
}

sub _default_label {
  my $self = shift;
  return $self->{label} if $self->{label};
  my $label = $self->{path}->[-1];
  $label =~ s/[^-a-z0-9]+/ /ig;
  $self->{label} = ucfirst $label;
}

sub _invalid_parameter {
  my ($field, $message) = @_;
  Carp::croak "Invalid parameter '$field': $message";
}

sub _path { "$_[0]->{name}${SEPARATOR}$_[1]" }

sub _lookup_value {
  my $self = shift;
  return $self->{value} if defined $self->{value};

  my $name = $self->{name};
  my $object = $self->{object};
  my @path = @{$self->{path}};

  if(!$object) {
    $object = $self->{c}->stash($path[0]);
    #_invalid_parameter($name, "nothing in the stash for '$path[0]'") unless $object;
  }

  # Remove the stash key for $object
  shift @path;

  while(defined(my $accessor = shift @path) && $object) {
    my $isa = ref($object);

    # We don't handle the case where one of these return an array
    if(Scalar::Util::blessed($object) && $object->can($accessor)) {
      $object = $object->$accessor;
    }
    elsif($isa eq 'HASH') {
      # If blessed and !can() do we _really_ want to look inside?
      $object = $object->{$accessor};
    }
    elsif($isa eq 'ARRAY') {
      _invalid_parameter($name, "non-numeric index '$accessor' used to access an ARRAY")
        unless $accessor =~ /^\d+$/;

      $object = $object->[$accessor];
    }
    else {
      my $type = $isa || 'type that is not a reference';
      _invalid_parameter($name, "cannot use '$accessor' on a $type");
    }
  }

  $self->{value} = $object if $object;
  $self->{value} = $self->{c}->param($name) unless $self->{value};
  $self->{value} //= '';
  return $self->{value};
}

sub _form_field {
  my $self = shift;
  my $type = shift;
  my $c = $self->{c};
  my $label;
  $label = shift if @_ % 2;
  $label //= $self->_default_label;
  my %options = @_;
  #my $error = $c->validator_error($self->{name});
  my $error = $c->validator_error($self->{path}->[-1]);

  if ($type eq 'radio' || $type eq 'checkbox') {
    $c->tag('div', class => $type, sub {
      my $content = $self->label(sub {
        $self->$type(%options) . ' ' . xml_escape($label);
      });
      $content .= $c->tag('p', class => 'text-danger', $error) if $error;
      return $content;
    });
  } else {
    $c->tag('div', class => ('form-group' . ($error ? ' has-error' : '')), sub {
      my $content = $self->label($label . ':');
      $content .= $self->$type(class => 'form-control', placeholder => $label, %options);
      $content .= $c->tag('p', class => 'text-danger', $error) if $error;
      return $content;
    });
  }
}

package PMLTQ::Server::FormHelpers::ScopedField;

use Mojo::Base -strict;
use Carp ();

our @ISA = 'PMLTQ::Server::FormHelpers::Field';

my $sep = __PACKAGE__->separator;

sub new {
  my $class = shift;
  Carp::croak 'object name required' unless $_[1];  # 0 arg is controller instance

  my $self = $class->SUPER::new(@_);
  $self->{fields} = {};
  $self->{index} = $1 if $self->{name} =~ /\Q$sep\E(\d+)$/;

  $self;
}

sub index  { shift->{index} }

# This is the caller's view of the object, which can differ from $self->{object}.
# For example, given 'user.orders.0.id' {object} will be user and object() will be user.orders.0
sub object { shift->_lookup_value }

my @methods = @PMLTQ::Server::FormHelpers::Field::TEXT_FIELD_TYPES;
push @methods, "${_}_field" for (@PMLTQ::Server::FormHelpers::Field::TEXT_FIELD_TYPES);

for my $m (@methods, qw(fields file hidden input label password password_field
  checkbox checkbox_field checkbox_options radio radio_field select textarea
  select_option select_option_field)) {
  no strict 'refs';
  *$m = sub {
    my $self = shift;
    my $name = shift;
    Carp::croak 'field name required' unless $name;

    return $self->_fields($name) if $m eq 'fields';

    my $field = $self->_field($name);
    $self->{fields}->{$name} = 1;

    $field->$m(@_);
  };
}

sub _field {
  my ($self, $name) = @_;
  $self->{c}->field($self->_path($name), $self->{object});
}

sub _fields {
  my ($self, $name) = @_;
  $self->{c}->fields($self->_path($name), $self->{object});
}

1;
