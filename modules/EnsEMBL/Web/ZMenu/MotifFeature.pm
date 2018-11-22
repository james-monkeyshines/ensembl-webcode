=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::ZMenu::MotifFeature;

use strict;

use base qw(EnsEMBL::Web::ZMenu::RegulationBase);

sub content {
  my ($self) = @_;

  my $hub     = $self->hub;
  my $click_data = $self->click_data;
  return unless $click_data;

  my $id = $hub->param('feature_id');
  $self->caption("Motif Feature: $id");
  my $r       = $hub->param('r');

  $self->add_entry({
                    type       => 'Location',
                    label_html => $r, 
                    link       => $hub->url({
                                    action  => 'View',
                                    r       => $r,
                                  }),
                    class      => '_motif',
                  });
  

  $self->add_entry({
                    type       => 'Binding matrix',
                    label_html => $hub->param('binding_matrix_stable_id'), 
                    link       => '#',
                    class      => '_motif',
                  });
  ## Split these fields with spaces so they wrap
  my @transcription_factors = split(',', $hub->param('transcriprion_factors'));
  $self->add_entry({
                    type        => 'Transcription factors',
                    label       => join (', ', @transcription_factors), 
                  });
  my @epigenomes = split(',', $hub->param('epigenomes'));
  @epigenomes = ('none') unless scalar @epigenomes;
  $self->add_entry({
                    type        => 'Verified in cell lines',
                    label       => join(', ', @epigenomes), 
                  });
}

sub _types_by_colour {
  my $self = shift;
  my $colours = $self->hub->species_defs->all_colours('fg_regulatory_features');
  my $colourmap = new EnsEMBL::Draw::Utils::ColourMap;
  my $lookup  = {};
  foreach my $col (keys %$colours) {
    my $raw_col = $colours->{$col}{'default'};
    my $hexcol = lc $colourmap->hex_by_name($raw_col);
    $lookup->{$hexcol} = $colours->{$col}{'text'};
  }
  return $lookup;
}

1;