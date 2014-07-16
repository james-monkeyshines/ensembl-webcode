=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::UserData::RemoteFeedback;

use strict;
use warnings;
no warnings "uninitialized";

use base qw(EnsEMBL::Web::Component::UserData);

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
}

sub caption {
  my $self = shift;
  return 'URL attached';
}

sub content {
  my $self = shift;
  my $hub = $self->hub;
  
  my $form = $self->new_form({'id' => 'url_feedback', 'method' => 'post'});

  my $message;
  if ($hub->param('format') eq 'DATAHUB') {
    my $sample_data = $hub->species_defs->get_config($hub->data_species, 'SAMPLE_DATA') || {};
    my $default_loc = $sample_data->{'LOCATION_PARAM'};
    $message = sprintf('<p class="space-below"><strong><a href="%s#modal_config_viewbottom-%s">Configure your hub</a></strong></p>',
      $hub->url({
              species   => $hub->data_species,
              type      => 'Location',
              action    => 'View',
              function  => undef,
              r         => $hub->param('r') || $default_loc,
      }),
      $hub->param('name'),
    );
  }
  else {
    $message = qq(Thank you - your remote data was successfully attached. Close this Control Panel to view your data);
  }

  $form->add_element(
      type  => 'Information',
      value => $message, 
    );
  $form->add_element( 'type' => 'ForceReload' );

  return $form->render;
}

1;
