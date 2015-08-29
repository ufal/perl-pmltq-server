package PMLTQ::Server::Controller::Treebank;

# ABSTRACT: Suggest query based on given nodes

use Mojo::Base 'Mojolicious::Controller';
use PMLTQ::Common;
use PMLTQ::Server::Validation;

sub suggest {
  my $c = shift;

  return $c->status_error({
    code => 500,
    message => "Suggest service not available or not defined"
  }) unless $c->config->{nodes_to_query_service};

  my $input = $c->_validate_suggest($c->req->json);

  return $c->render_validation_errors unless $input;

  my $tb = $c->stash('tb');
  my @f = eval {
    my $evaluator = $tb->get_evaluator;
    $evaluator->ids_to_pos($input->{ids}, 1);
  };

  return $c->status_error({
    code => 500,
    message => "Evaluator initialize failed: $@"
  }) if $@;

  my @paths;
  foreach my $f (@f) {
    my $path;
    my $goto = $1 if $f =~ s{(#.*$)}{};
    $path = $tb->resolve_data_path($f, $c->config->{data_dir});
    return $c->status_error({
      code => 404,
      message => "File $f not found"
    }) unless defined $path && -e $path;
    push @paths, [$path, $goto];
  }

  my $url = Mojo::URL->new($c->config->{nodes_to_query_service});
  $url->query(p => join('|', @paths), ($input->{vars} ? (r => $input->{vars}) : ()));
  $c->app->ua->get($url => sub {
      my ($ua, $tx) = @_;
      if (my $res = $tx->success) {
        $c->render(json => {
          query => $res->text
        });
      } else {
        my ($err, $code) = $tx->error;
        $c->status_error({
          code => $code||500,
          message => ref $err ? $err : "$err"
        })
      }
  });

  $c->render_later;
}

sub _validate_suggest {
  my ($c, $data) = @_;

  my $rules = {
    fields => [qw/ids vars/],
    checks => [
      ids => [is_required('ids not specified'),
              is_a('ARRAY', 'ids have to be an array'),
              sub {
                my $ids = shift;
                return "ids array is empty" unless @$ids > 0;
                for (my $index = 0; $index < @$ids; $index++) {
                  my $node_id = @{$ids}[$index];
                  return "node id ($index) is empty" unless $node_id
                }
              }],
      reserved_names => is_a('ARRAY', 'reserved_names have to be an array')
    ]
  };

  $c->do_validation($rules, $data);
}

sub _pmltq_string {
  my ($string)=@_;
  $string=~s/([\\'])/\\$1/g;
  $string=~s/(\n)/\\n/g;
  return qq{'$string'};
}

sub nodes_to_pmltq {
  my ($nodes, $opts)=@_;
  $opts ||= {};

  my %id_member;
  my $name = 'a';
  $name++ while $opts->{reserved_names} && exists($opts->{reserved_names}{$name});
  my %node2name;
  $opts->{id2name} = { map {
    my $n = $_->[0];
    my $t = $n->type;
    my $id_member = ( $id_member{$t} ||= _id_member_name($t) );
    my $var = $node2name{$n} = $name++;
    $name++ while $opts->{reserved_names} && exists($opts->{reserved_names}{$name});
    ($n->{$id_member} => $var)
  } @$nodes };

  # discover relations;
  my %marked;
  @marked{map $_->[0], @$nodes}=(); # undef by default, 1 if connected
  my %parents=();
  my %connect;
  for my $m (@$nodes) {
    my ($n,$fsfile)=@$m;
    my $parent = $n->parent;
    $parents{$parent}||=$n;
    if ($parent and exists($marked{$parent})) {
      push @{$connect{$n->parent}{child}}, $n;
      # print STDERR "$node2name{$n->parent} has child $node2name{$n}\n";
      $marked{$n}=1;
    } elsif ($parents{$parent}!=$n) {
      push @{$connect{$parents{$parent}}{sibling}}, $n;
      # print STDERR "$node2name{$parents{$parent}} has sibling $node2name{$n}\n";
      $marked{$n}=1;
    } else {
      $parent = $parent && $parent->parent;
      while ($parent) {
  if (exists $marked{$parent}) {
    # print STDERR "$node2name{$parent} has descendant $node2name{$n}\n";
    push @{$connect{$parent}{descendant}}, $n;
    $marked{$n}=1;
    last;
  }
  $parent = $parent->parent;
      }
    }
  }
  $opts->{connect}=\%connect;
  return join(";\n\n", map {
    node_to_pmltq($_->[0],$_->[1],$opts)}
    grep { !$marked{$_->[0]} } @$nodes);
}

sub node_to_pmltq {
  my ($node,$fsfile,$opts)=@_;
  return unless $node;
  my $type = $node->type;
  return unless $type;
  my $out='';
  my $indent = $opts->{indent} || '';

  my $var = $opts->{id2name} && $opts->{id2name}{$node->{_id_member_name($node->type)}};
  $var = ' $'.$var.' := ' if $var;

  $out .= PMLTQ::Common::DeclToQueryType($type).$var." [\n";
  foreach my $attr ('#name',$type->get_normal_fields) {
    my $m = $type->get_member_by_name($attr);
    # next if $m and $m->get_role() eq '#ID';
    my $val = $node->{$attr};
    next unless defined $val;
    $m = $type->get_member_by_name($attr.'.rf') unless $m;
    if ($attr eq '#name') {
      $out .= $indent.qq{  name() = }._pmltq_string($val).qq{,\n};
      next;
    } elsif (!$m) {
      $out .= $indent." # $attr ???;" unless $opts->{no_comments};
      next;
    }
    my $name = $attr eq '#content' ? 'content()' : $attr;
    next if $opts->{exclude} and $opts->{exclude}{$name};
    $out.=member_to_pmltq($name,$val,$m,$indent.'  ',$fsfile,$opts);
  }
  if (defined $opts->{rbrothers}) {
    $out .= $indent.qq{  # rbrothers()=$opts->{rbrothers},\n} unless $opts->{no_comments};
  }
  if ($opts->{connect}) {
    my $rels = $opts->{connect}{$node};
    if ($rels) {
      foreach my $rel (sort keys %$rels) {
  foreach my $n (@{$rels->{$rel}}) {
    $out.='  '.$indent.$rel.' '.node_to_pmltq($n,$fsfile,{
      %$opts,
      indent=>$indent.'  ',
    }).",\n";
  }
      }
    }
  } elsif ($opts->{children} or $opts->{descendants}) {
    my $i = 0;
    my $son = $node->firstson;
    while ($son) {
      $out.='  '.$indent.'child '.node_to_pmltq($son,$fsfile,{
  %$opts,
  indent=>$indent.'  ',
  children => 0,
  rbrothers=>$i,
      }).",\n";
      $i++;
      $son=$son->rbrother;
    }
    $out .= $indent.qq{  # sons()=$i,\n} unless $opts->{no_comments};
  }
  $out.=$indent.']';
  return $out;

}

sub resolve_pmlref {
  my ($ref,$fsfile)=@_;
  if ($ref=~m{^(.+?)\#(.+)$}) {
    my ($file_id,$id)=($1,$2);
    my $refs = $fsfile->appData('ref');
    my $reffile = $refs && $refs->{$file_id};
    if (UNIVERSAL::DOES::does($reffile,'Treex::PML::Document')) {
      return PML::GetNodeByID($id,$reffile);
    } elsif (UNIVERSAL::DOES::does($reffile,'Treex::PML::Instance')) {
      return $reffile->lookup_id($id);
    }
  } elsif ($ref=~m{\#?([^#]+)}) {
    return PML::GetNodeByID($1);
  }
  return undef;
}

sub member_to_pmltq {
  my ($name, $val, $type, $indent, $fsfile, $opts)=@_;
  my $out;
  my $mtype = $name eq 'content()' ? $type : $type->get_knit_content_decl;
  if ($mtype->get_decl_type == PML_ALT_DECL and !UNIVERSAL::DOES::does($val,'Treex::PML::Alt')) {
    $mtype = $mtype->get_knit_content_decl;
  }
  if (not ref($val)) {
    if (!$mtype->is_atomic) {
      $out.=$indent."# ignoring $name\n",
    } else {
      my $is_pmlref = (($mtype->get_decl_type == PML_CDATA_DECL) and ($mtype->get_format eq 'PMLREF')) ? 1 : 0;
      if ($type and ($type->get_role() =~ /^#(ID|ORDER)$/ or $is_pmlref)) {
  if ($is_pmlref and $opts->{id2name} and $val=~/(?:^.*?\#)?(.+)$/ and $opts->{id2name}{$1}) {
    $out .= $indent.qq{$name \$}.$opts->{id2name}{$1}.qq{,\n};
  } elsif ($is_pmlref) {
    my $target = resolve_pmlref($val,$fsfile);
    if ($target && $target->type) {
      $out.=$indent.'# '.$name.' '.Tree_Query::Common::DeclToQueryType( $target->type ).qq{ [ ],\n};
    } else {
      $out.=$indent.'# '.$name.qq{->[ ],\n};
    }
  } elsif ($opts->{no_comments}) {
    return;
  } else {
    $out.=$indent.'# '.qq{$name = }._pmltq_string($val).qq{,\n};
  }
      } else {
  $out.=$indent;
  $out.=qq{$name = }._pmltq_string($val).qq{,\n};
      }
    }
  } elsif (UNIVERSAL::DOES::does($val,'Treex::PML::List')) {
    if ($mtype->is_ordered) {
      my $i=1;
      foreach my $v (@$val) {
  $out.=member_to_pmltq("$name/[$i]",$v,$mtype,$indent,$fsfile,$opts);
  $i++;
      }
    } else {
      foreach my $v (@$val) {
  $out.=member_to_pmltq($name,$v,$mtype,$indent,$fsfile,$opts);
      }
    }
  } elsif (UNIVERSAL::DOES::does($val,'Treex::PML::Alt')) {
    foreach my $v (@$val) {
      $out.=member_to_pmltq($name,$v,$mtype,$indent,$fsfile,$opts);
    }
  } elsif (UNIVERSAL::DOES::does($val,'Treex::PML::Struct') or UNIVERSAL::DOES::does($val,'Treex::PML::Container')) {
    $out.=$indent.qq{member $name \[\n};
    foreach my $attr ($mtype->get_normal_fields) {
      my $m = $mtype->get_member_by_name($attr);
      # next if $m and $m->get_role() eq '#ID';
      my $v = $val->{$attr};
      next unless defined $v;
      $m = $mtype->get_member_by_name($attr.'.rf') unless $m;
      if (!$m) {
  $out .= " # $attr ???;" unless $opts->{no_comments};
  next;
      }
      my $n = $attr eq '#content' ? 'content()' : $attr;
      next if $opts->{exclude} and $opts->{exclude}{$n};
      $out.=member_to_pmltq($n,$v,$m,$indent.'  ',$fsfile,$opts);
    }
    $out.=$indent.qq{],\n}
  } elsif (UNIVERSAL::DOES::does($val,'Treex::PML::Seq')) {
    my $i=1;
    foreach my $v ($val->elements) {
      my $n = $v->name;
      next if $opts->{exclude} and $opts->{exclude}{$n};
      $out.=member_to_pmltq("$name/[$i]$n",$v->value,$mtype->get_element_by_name($n),$indent,$fsfile,$opts);
      $i++;
    }
  }
  return $out;
}

sub _id_member_name {
  my ($type)=@_;
  return undef unless $type;
  if ($type->get_decl_type == PML_ELEMENT_DECL) {
    $type = $type->get_content_decl;
  }
  my ($omember) = $type->find_members_by_role('#ID');
  if ($omember) {
    return ($omember->get_name);
  }
  return undef; # we want this undef
}

1;
