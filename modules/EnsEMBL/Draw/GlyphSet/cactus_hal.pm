=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2017] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Draw::GlyphSet::_alignment_pairwise;

### Draws compara pairwise alignments - see EnsEMBL::Web::ImageConfig
### and E::W::ImageConfig::MultiBottom for usage

use strict;

use EnsEMBL::Draw::Style::Feature;

use base qw(EnsEMBL::Draw::GlyphSet);

# Useful for debugging. Should all be 0 in checked-in code.
my $debug_force_cigar   = 0; # CIGAR at all resolutions
my $debug_rainbow       = 0; # Joins in rainbow colours to tell them apart
my $debug_force_compact = 0; # render_normal -> render_compact

sub init {
  my $self = shift;

  ## Fetch and cache features
  my $data = $self->get_data;
  my $features = $data->[0]{'features'} || [];
 
  ## No features show "empty track line" if option set
  if ($features eq 'too_many') {
    $self->too_many_features;
    return [];
  }
  elsif (!scalar(@$features)) {
    $self->no_features;
    return [];
  }

  ## Set track depth (i.e. number of rows of features)  
  my $depth = $self->depth;
  $depth    = 1e3 unless defined $depth;
  $self->{'my_config'}->set('depth', $depth);

  ## Set track height
  $self->{'my_config'}->set('height', '10');
  
  ## OK, done!
  return $features;
}


sub render_normal {
  my $self = shift;
  warn ">>> RENDERING NORMAL";

  return $self->render_compact if $debug_force_compact;

  $self->{'my_config'}->set('bumped', 1)

  my $data = $self->get_data;
  if (scalar @{$data->[0]{'features'}||[]}) {
    my $config = $self->track_style_config;
    my $style  = EnsEMBL::Draw::Style::Feature->new($config, $data);
    $self->push($style->create_glyphs);
  }
  else {
    $self->no_features;
  }

}

sub render_compact {
  my $self = shift;

}

sub get_data {
  my $self = shift;
  warn "@@@ GETTING FEATURES";

  ## Check the cache first
  my $cache_key = $self->my_label;
  if ($self->feature_cache($cache_key)) {
    warn "!!! FOUND CACHED DATA";
    return $self->feature_cache($cache_key);
  }

  my $compara = $self->dbadaptor('multi',$self->my_config('db'));
  my $mlss_a  = $compara->get_MethodLinkSpeciesSetAdaptor;
  my $mlss_id = $self->my_config('method_link_species_set_id');
  my $mlss    = $mlss_a->fetch_by_dbID($mlss_id);
  my $gab_a   = $compara->get_GenomicAlignBlockAdaptor;

  #Get restricted blocks
  my $features = $gab_a->fetch_all_by_MethodLinkSpeciesSet_Slice($mlss,$cont, undef, undef, 'restrict');

  ## Build features into sorted groups
  my $slice       = $self->{'container'};
  my @slices      = split(' ',$self->my_config('slice_summary')||'');
  my $strand_flag = $self->my_config('strand');
  my $length      = $slice->length;
  my $strand      = $self->strand;
  my %groups;
  my $k = 0;

  ## Build into groups
  foreach my $gab (@{$features||[]}) {
    my $start     = $gab->reference_slice_start;
    my $end       = $gab->reference_slice_end;
    my $nonref    = $gab->get_all_non_reference_genomic_aligns->[0];
    my $hseqname  = $nonref->dnafrag->name;
   
    next if $end < 1 || $start > $length;
    my $key = $hseqname . ':' . ($gab->group_id || ('00' . $k++));

    ## Convert GAB into something the drawing code can understand


    push @{$groups{$key}{'gabs'}},[$start,$gab];
  }

  ## Sort contents of groups by start
  foreach my $group (values %groups) {
    my @f = map {$_->[1]} sort { $a->[0] <=> $b->[0] } @{$g->{'gabs'}};
    $group->{'len'} = max(map { $_->reference_slice_end   } @f) -
                      min(map { $_->reference_slice_start } @f);
    $group->{'gabs'} = \@f;
    $group->{'special'} = $self->is_special($g->{'gabs'},\@slices);
  }

  # Sort by length
  my @sorted = map { $_->{'gabs'} } sort {
      ($b->{'special'} <=> $a->{'special'}) ||
      ($b->{'len'} <=> $a->{'len'})
    } values %groups;

  ## Set cache
  my $data = [{'features' => \@sorted}]
  $self->feature_cache($cache_key, $data);
  return $data;
}

1;
