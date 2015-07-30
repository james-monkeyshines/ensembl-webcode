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

package EnsEMBL::Web::IOWrapper::GTF;

### Wrapper for Bio::EnsEMBL::IO::Parser::GTF, which builds
### simple hash features suitable for use in the drawing code 

use strict;
use warnings;
no warnings 'uninitialized';

use parent qw(EnsEMBL::Web::IOWrapper);


sub build_feature {
### Parse exons separately from other features
  my ($self, $data, $track_key, $slice) = @_;

  my $type = $self->parser->get_type;

  if ($type eq 'exon') {
    my $attribs = $self->parser->get_attributes;
    my $transcript_id = $attribs->{'transcript_id'};
    if ($data->{$track_key}{'transcripts'}{$transcript_id}) {
      push @{$data->{$track_key}{'transcripts'}{$transcript_id}}, $self->create_hash($data->{$track_key}{'metadata'}, $slice);
    }
    else {
      $data->{$track_key}{'transcripts'}{$transcript_id} = [$self->create_hash($data->{$track_key}{'metadata'}, $slice)];
    }
  }
  else { ## Single feature - add to track as normal
    if ($data->{$track_key}{'features'}) {
      push @{$data->{$track_key}{'features'}}, $self->create_hash($data->{$track_key}{'metadata'}, $slice);
    }
    else {
      $data->{$track_key}{'features'} = [$self->create_hash($data->{$track_key}{'metadata'}, $slice)];
    }
  }
}

sub post_process {
### Reassemble sub-features back into features
  my ($self, $data) = @_;
  
  while (my ($track_key, $content) = each (%$data)) {
    next unless $content->{'transcripts'};
    while (my ($transcript_id, $exons) = each (%{$content->{'transcripts'}})) {
      my $no_of_exons = scalar(@{$exons||[]});
      next unless $no_of_exons;

      my $hash = {'structure' => []};
      
      foreach (sort {$a->{'exon_number'} <=> $b->{'exon_number'}} @$exons) {
        $hash->{'seq_region'} = $_->{'seq_region'};  
        $hash->{'start'}      = $_->{'start'} if $_->{'exon_number'} == 1;
        $hash->{'end'}        = $_->{'end'} if $_->{'exon_number'} == $no_of_exons;
        $hash->{'strand'}     = $_->{'strand'};
        $hash->{'colour'}     = $_->{'colour'};
        $hash->{'label'}    ||= $_->{'transcript_name'} || $_->{'transcript_id'};
        push @{$hash->{'structure'}}, {'start' => $_->{'start'}, 'end' => $_->{'end'}};
      }

      if ($data->{$track_key}{'features'}) {
        push @{$data->{$track_key}{'features'}}, $hash; 
      }
      else {
        $data->{$track_key}{'features'} = [$hash]; 
      }
    }
  }
}

sub create_hash {
### Create a hash of feature information in a format that
### can be used by the drawing code
### @param metadata - Hashref of information about this track
### @param slice - Bio::EnsEMBL::Slice object
### @return Hashref
  my ($self, $metadata, $slice) = @_;
  $metadata ||= {};
  return unless $slice;

  ## Start and end need to be relative to slice,
  ## as that is how the API returns coordinates
  my $feature_start = $self->parser->get_start;
  my $feature_end   = $self->parser->get_end;

  ## Only set colour if we have something in metadata, otherwise
  ## we will override the default colour in the drawing code
  my $colour;
  my $strand  = $self->parser->get_strand;
  my $score   = $self->parser->get_score;

  if ($metadata->{'useScore'}) {
    $colour = $self->convert_to_gradient($score, $metadata->{'color'});
  }
  elsif ($metadata->{'colorByStrand'} && $strand) {
    my ($pos, $neg) = split(' ', $metadata->{'colorByStrand'});
    my $rgb = $strand == 1 ? $pos : $neg;
    $colour = $self->rgb_to_hex($rgb);
  }
  elsif ($metadata->{'color'}) {
    $colour = $metadata->{'color'};
  }

  ## Try to find an ID for this feature, by taking
  ## the first attribute ending in 'id'
  my $attributes = $self->parser->get_attributes;
  my $id = $attributes->{'transcript_id'} || $attributes->{'gene_id'};

  ## Not a transcript, so just grab a likely attribute
  if (!$id) {
    while (my ($k, $v) = each (%$attributes)) {
      if ($k =~ /id$/i) {
        $id = $v;
        last;
      }
    }
  }

  return {
    'start'         => $feature_start - $slice->start,
    'end'           => $feature_end - $slice->start,
    'seq_region'    => $self->parser->get_seqname,
    'strand'        => $strand,
    'score'         => $score,
    'colour'        => $colour, 
    'label'         => $id,
    %$attributes,
  };
}

1;