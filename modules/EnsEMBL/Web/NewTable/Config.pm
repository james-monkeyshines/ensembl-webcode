=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::NewTable::Config;

use strict;
use warnings;

use Carp;

our @PLUGINS = qw(Core Frame Decorate Filter Misc Paging);
our %PLUGINS;

use EnsEMBL::Web::NewTable::Column;
use EnsEMBL::Web::Utils::DynamicLoader qw(dynamic_require);

# Load Plugin packages

my @PACKAGES;
while(@PLUGINS) {
  my $plugin = shift @PLUGINS;
  my $package = dynamic_require("EnsEMBL::Web::NewTable::Plugins::$plugin",1);
  push @PACKAGES,$plugin;
  if($package) {
    my $children = $package->children();
    push @PLUGINS,@$children;
  }
}
foreach my $plugin (@PACKAGES) {
  my $package = "EnsEMBL::Web::NewTable::Plugins::$plugin";
  if(UNIVERSAL::isa($package,"EnsEMBL::Web::NewTable::Plugin")) {
    $PLUGINS{$plugin} = $package;
  }
}

#

sub new {
  my ($proto,$hub,$config,$ssplugins,$keymeta) = @_;

  $ssplugins ||= {};
  $keymeta ||= {};
  $config ||= { type => undef, colconf => {} };
  my $class = ref($proto) || $proto;
  my $self = {
    colorder => $config->{'columns'},
    columns => {},
    type => $config->{'type'},
    plugins => {},
    phases => $config->{'phases'},
    keymeta => $config->{'keymeta'},
    size_needed => 0,
    hub => $hub,
    memo => {
      config => $config, ssplugins => $ssplugins, keymeta => $keymeta
    }
  };
  bless $self,$class;
  foreach my $name (keys %$ssplugins) {
    $name =~ s/\W//g;
    $self->_add_plugin($name,$ssplugins->{$name});
  } 
  foreach my $key (keys %{$config->{'colconf'}}) {
    my $cc = $config->{'colconf'}{$key};
    $self->{'columns'}{$key} =
      EnsEMBL::Web::NewTable::Column->new(
        $self,$cc->{'sstype'},$key,$cc->{'ssconf'},$cc->{'ssarg'}
      );
  }
  return $self;
}

sub memo_argument { return $_[0]->{'memo'}; }

sub register_key {
  my ($self,$key,$meta) = @_; 

  $self->{'key_meta'}{$key}||={};
  foreach my $k (keys %{$meta||{}}) {
    $self->{'key_meta'}{$key}{$k} = $meta->{$k} unless exists $self->{'key_meta'}{$key}{$k};
  }   
}

sub add_keymeta {
  my ($self,$key,$meta) = @_;

  $self->{'keymeta'}{$key}||={};
  foreach my $k (keys %{$meta||{}}) {
    $self->{'keymeta'}{$key}{$k} = $meta->{$k} unless exists $self->{'keymeta'}{$key}{$k};
  } 
}

sub columns { return $_[0]->{'colorder'}; }
sub column { return $_[0]->{'columns'}{$_[1]}; }
sub type { return $_[0]->{'type'}; }
sub phase {
  my ($self,$idx) = @_;
  my %phase = %{$self->{'phases'}[$idx]};
  $phase{'cols'} = $self->columns unless defined $phase{'cols'};
  return \%phase;
}

sub num_phases { return @{$_[0]->{'phases'}}; }
sub keymeta { return $_[0]->{'keymeta'}; }

sub _add_plugin {
  my ($self,$plugin,$conf,$_ours) = @_;
  return 0 unless $PLUGINS{$plugin};
  my $pp = $self->{'plugins'}{$plugin};
  $self->{'plugins'}{$plugin} = $PLUGINS{$plugin}->new($self,$self->{'hub'}) unless $pp;
  $pp = $self->{'plugins'}{$plugin};
  return 0 unless $pp;
  $pp->configure($conf);
  foreach my $sub (@{$pp->requires()}) {
    next if $_ours->{$sub};
    $_ours->{$sub} = 1;
    return 0 unless $self->_add_plugin($sub,$conf,$_ours);
  }
  return 1;
}

sub size_needed {
  $_[0]->{'size_needed'} = $_[1] if @_>1;
  return $_[0]->{'size_needed'};
}

sub plugins {
  my ($self) = @_; 

  my %out;
  foreach my $plugin (keys %{$self->{'plugins'}}) {
    $out{$plugin} = $self->{'plugins'}{$plugin}{'conf'};
  }
  return \%out;
}

sub can_delegate {
  my ($self,$type,$fn) = @_; 

  $fn = "${type}_$fn" if $type;
  foreach my $plugin (values %{$self->{'plugins'}}) {
    if($plugin->can($fn)) {
      return 1;
    }   
  }
  return 0;
}

sub delegate {
  my ($self,$obj,$type,$fn,$data) = @_; 

  my $orig_fn = $fn;
  $fn = "${type}_$fn" if $type;
  foreach my $plugin (values %{$self->{'plugins'}}) {
    if($plugin->can($fn)) {
      return $plugin->$fn($obj,@$data);
    }
  }
  confess "No such method '$orig_fn'";
}

sub orient_out {
  my ($self) = @_;

  my $orient = { format => 'Tabular' };
  foreach my $p (values %{$self->{'plugins'}}) {
    $orient = { %$orient, %{$p->initial} };
  }
  return $orient;
}

sub config {
  my ($self) = @_;

  my %widgets;
  foreach my $p (keys %{$self->{'plugins'}}) {
    $widgets{$p} = [
      $self->{'plugins'}{$p}->js_plugin,
      $self->{'plugins'}{$p}->js_config,
    ];
  }

  my %colconf;
  $colconf{$_} = $self->{'columns'}{$_}->colconf for keys %{$self->{'columns'}};
  
  return {
    columns => $self->{'colorder'},
    orient => $self->orient_out,
    formats => ["tabular","paragraph"],
    colconf => \%colconf,
    widgets => \%widgets,
    phases => $self->{'phases'},
    keymeta => $self->{'keymeta'},
    ssplugins => $self->plugins
  };
}

1;
