=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::DBHub;

### A centralised object giving access to data base connections
### This object can be safely used in scripts where the process in not a web based request

use strict;
use warnings;

use Bio::EnsEMBL::Registry;

use EnsEMBL::Web::Attributes;
use EnsEMBL::Web::DBSQL::DBConnection;
use EnsEMBL::Web::Exceptions qw(DBException);
use EnsEMBL::Web::SpeciesDefs;

use parent qw(EnsEMBL::Web::Root);

sub species       :Accessor;
sub species_defs  :Accessor;

sub new {
  ## @constructor
  ## @param Species production name (optional)
  ## @param SpeciesDefs object (optional - creates a new one if missing)
  my ($class, $species, $species_defs) = @_;

  # Create SpeciesDefs if missing
  $species_defs ||= EnsEMBL::Web::SpeciesDefs->new;

  # TODO - get rid of %ENV usage
  $ENV{'ENSEMBL_SPECIES'} = $species;

  return bless {
    'species'       => $species,
    'species_defs'  => $species_defs
  }, $class;
}

sub databases {
  ## Gets DBConnection object
  my $self = shift;

  return $self->{'databases'} ||= EnsEMBL::Web::DBSQL::DBConnection->new($self->species, $self->species_defs);
}

sub database {
  ## Gets an API Database Adaptor according to type and species
  ## @param (String) DB type
  ## @param (String) Species (if not the default one)
  my $self = shift;

  if ($_[0] && $_[0] =~ /compara/) {
    return Bio::EnsEMBL::Registry->get_DBAdaptor('multi', $_[0], 1);
  } else {
    return $self->databases->get_DBAdaptor(@_);
  }
}

sub get_adaptor {
  ## Gets an adaptor for a API object
  ## @param Method as required by the API DB Adaptor
  ## @param DB type (defaults to 'core')
  ## @param Species name (if different from the default one)
  my ($self, $method, $db, $species) = @_;

  $db      ||= 'core';
  $species ||= $self->species;

  my $adaptor;
  try {
    $adaptor = $self->database($db, $species)->$method;
  } catch {
    throw DBException($_);
  };

  return $adaptor;
}

1;