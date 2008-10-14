package EnsEMBL::Web::Configuration::Gene;

use strict;
use Bio::AlignIO; # Needed for tree alignments
use EnsEMBL::Web::RegObj;

use base qw( EnsEMBL::Web::Configuration );

## Function to configure gene snp view

sub set_default_action {
  my $self = shift;
  $self->{_data}{default} = 'Summary';
}

sub populate_tree {
  my $self = shift;
#  my $hash = $obj->get_summary_counts;

  $self->create_node( 'Summary', "Summary",
    [qw(summary EnsEMBL::Web::Component::Gene::GeneSummary
        transcripts EnsEMBL::Web::Component::Gene::TranscriptsImage)],
    { 'availability' => 1, 'concise' => 'Gene summary' }
  );

  $self->create_node( 'Splice', "Alternative splicing ([[counts::exons]] exons)",
    [qw(image       EnsEMBL::Web::Component::Gene::GeneSpliceImage)],
    { 'availability' => 1, 'concise' => 'Alternative splicing' }
  );

  $self->create_node( 'Evidence', "Supporting evidence",
     [qw(evidence       EnsEMBL::Web::Component::Gene::SupportingEvidence)],
    { 'availability' => 1, 'concise' => 'Supporting evidence'}
  );

  $self->create_node( 'Sequence', "Marked-up sequence",
     [qw(sequence       EnsEMBL::Web::Component::Gene::GeneSeq)],
    { 'availability' => 1, 'concise' => 'Marked-up sequence'}
  );

  $self->create_node( 'Matches', "Similarity matches ([[counts::similarity_matches]])",
     [qw(matches       EnsEMBL::Web::Component::Gene::SimilarityMatches)],
    { 'availability' => 1, 'concise' => 'SimilarityMatches'}
  );

  $self->create_node( 'Regulation', 'Regulation',
    [qw(
      regulation EnsEMBL::Web::Component::Gene::RegulationImage
      features EnsEMBL::Web::Component::Gene::RegulationTable
    )],
    { 'availability' => 'database:funcgen' }
  );

# $self->create_node( 'XRefs', "External references",
#   [qw(xrefs EnsEMBL::Web::Component::Gene::XRefs)],
#   { 'availability' => 1, 'concise' => 'XRefs' }
# );

##----------------------------------------------------------------------
## Compara menu: alignments/orthologs/paralogs/trees
  my $compara_menu = $self->create_submenu( 'Compara', 'Comparative genomics' );
  $compara_menu->append( $self->create_node( 'Compara_Alignments', "Genomic alignments ([[counts::alignments]])",
    [qw(alignment_options  EnsEMBL::Web::Component::Gene::ComparaAlignmentsOptions),
     qw(alignments  EnsEMBL::Web::Component::Gene::ComparaAlignments), ],
    { 'availability' => 'database:compara', 'concise' => 'Genomic alignments' }
  ));

## Compara tree
  my $tree_node = $self->create_node(
    'Compara_Tree', "Gene Tree",
    [qw(image        EnsEMBL::Web::Component::Gene::ComparaTree)],
    { 'availability' => 'database:compara' }
  );
  $tree_node->append( $self->create_subnode(
    'Compara_Tree/Text', "Gene Tree (text)",
    [qw(treetext        EnsEMBL::Web::Component::Gene::ComparaTree/text)],
    { 'availability' => 'database:compara' }
  ));

  $tree_node->append( $self->create_subnode(
    'Compara_Tree/Align',       "Gene Tree (alignment)",
    [qw(treealign      EnsEMBL::Web::Component::Gene::ComparaTree/align)],
    { 'availability' => 'database:compara' }
  ));
  $compara_menu->append( $tree_node );

  my $ol_node = $self->create_node(
    'Compara_Ortholog',   "Orthologues ([[counts::orthologs]])",
    [qw(orthologues EnsEMBL::Web::Component::Gene::ComparaOrthologs)],
    { 'availability' => 'database:compara', 
      'concise'      => 'Orthologues' }
  );
  $compara_menu->append( $ol_node );
  $ol_node->append( $self->create_subnode(
    'Compara_Ortholog/Alignment', 'Ortholog Alignment',
    [qw(alignment EnsEMBL::Web::Component::Gene::HomologAlignment)],
    { 'availability'  => 'database:compara',
      'no_menu_entry' => 1 }
  ));
  my $pl_node = $self->create_node(
    'Compara_Paralog',    "Paralogues ([[counts::paralogs]])",
    [qw(paralogues  EnsEMBL::Web::Component::Gene::ComparaParalogs)],
    { 'availability' => 'database:compara', 
           'concise' => 'Paralogues' }
  );
  $compara_menu->append( $pl_node );
  $pl_node->append( $self->create_subnode(
    'Compara_Paralog/Alignment', 'Paralog Alignment',
    [qw(alignment EnsEMBL::Web::Component::Gene::HomologAlignment)],
    { 'availability'  => 'database:compara',
      'no_menu_entry' => 1 }
  ));
  my $fam_node = $self->create_node(
    'Family', 'Protein families ([[counts::families]])',
    [qw(family EnsEMBL::Web::Component::Gene::Family)],
    { 'availability' => 1, 'concise' => 'Protein families' }
  );
  $compara_menu->append($fam_node);
  my $sd = my $obj  = $self->{'object'}->species_defs;
  $fam_node->append($self->create_subnode(
    'Family/Genes', 'Other '.$sd->SPECIES_COMMON_NAME.' genes in this family',
    [qw(genes    EnsEMBL::Web::Component::Gene::FamilyGenes)],
    { 'availability'  => 'database:compara',
      'no_menu_entry' => 1 }
  ));
  $fam_node->append($self->create_subnode(
    'Family/Proteins', 'Other proteins in this family',
    [qw(proteins    EnsEMBL::Web::Component::Gene::FamilyProteins)],
    { 'availability'  => 'database:compara',
      'no_menu_entry' => 1 }
  ));

=pod
  my $user_menu = $self->create_submenu( 'User', 'User data' );
  $user_menu->append( $self->create_node( 'User_Notes', "User's gene based annotation",
    [qw(manual_annotation EnsEMBL::Web::Component::Gene::UserAnnotation)],
    { 'availability' => 1 }
  ));
=cut

## Variation tree
  my $var_menu = $self->create_submenu( 'Variation', 'Variational genomics' );
  $var_menu->append($self->create_node( 'Variation_Gene',  'Gene variations',
    [qw(image       EnsEMBL::Web::Component::Gene::GeneSNPImage)],
    { 'availability' => 'database:variation' }
  ));

  $self->create_node( 'Idhistory', 'ID history',
    [qw(display     EnsEMBL::Web::Component::Gene::HistoryReport
        associated  EnsEMBL::Web::Component::Gene::HistoryLinked
        map         EnsEMBL::Web::Component::Gene::HistoryMap)],
        { 'availability' => 1, 'concise' => 'ID History' }
  );

}

sub global_context { return $_[0]->_global_context; }
sub ajax_content   { return $_[0]->_ajax_content;   }

sub configurator {
  return $_[0]->_configurator;
}

sub ajax_zmenu      {
  my $self = shift;
  my $panel = $self->_ajax_zmenu;
  my $obj  = $self->object;

  my $action = $obj->[1]{'_action'} || 'Summary'; 
  warn $action;

  if( $action =~ 'Idhistory'){
    return $self->_ajax_zmenu_id_history_tree($panel, $obj);
  }

  if( $action =~ 'Regulation'){
    return $self->_ajax_zmenu_regulation($panel, $obj);
  }

  if( $action =~ 'Compara_Tree_Node' ){
    return $self->_ajax_zmenu_compara_tree_node();
  }

  my( $disp_id, $X,$Y, $db_label ) = $obj->display_xref;
  $panel->{'caption'} = $disp_id ? "$db_label: $disp_id" : 'Novel transcript';

  if( $action =~ 'Compara_Tree' ){
    my $species = $obj->species;
    $panel->add_entry({
      'type'     => 'Species',
      'label'    => $species,
      'link'     => "/$species",
      'priority' => 200
        });    

    # Link to protein sequence for cannonical or longest translation
    my $ens_tran = $obj->Obj->canonical_transcript;
    my $ens_prot;
    unless( $ens_tran ){
      my ($longest) = ( sort{ $b->[1]->length <=> $a->[1]->length } 
                        map{[$_, ( $_->translation || next ) ]} 
                        @{$obj->Obj->get_all_Transcripts} );
      ($ens_tran, $ens_prot) = @{$longest||[]};
    }
    if( $ens_prot ){
      $panel->add_entry({
        'type'     => 'Protein',
        'label'    => $ens_prot->display_id,
        'link'     => $obj->_url({'type'=>'Transcript',
                                  'action'=>'Sequence_Protein',
                                  't'=>$ens_tran->stable_id }),
        'priority' => 180
          });
    }

    # Link to TreeFam
    # Currently broken!
    warn( "==> @$obj" );
    if( my $treefam_link = $obj->get_ExtUrl($obj->stable_id, 'TREEFAM') ){
      $panel->add_entry({
        'type'     => 'TreeFam',
        'label'    => 'TreeFam',
        'link'     => $treefam_link,
        'priority' => 195,
        'extra'     => {'external' => 1}, 
      });
    }
  }

  $panel->add_entry({
    'type'     => 'Gene',
    'label'    => $obj->stable_id,
    'link'     => $obj->_url({'type'=>'Gene', 'action'=>$action}),
    'priority' => 195
  });
  $panel->add_entry({
    'type'     => 'Location',
    'label'    => sprintf( "%s: %s-%s",
                    $obj->neat_sr_name($obj->seq_region_type,$obj->seq_region_name),
                    $obj->thousandify( $obj->seq_region_start ),
                    $obj->thousandify( $obj->seq_region_end )
                  ),
    'link' => $obj->_url({'type'=>'Location',   'action'=>'View'   })
  });
  $panel->add_entry({
    'type'     => 'Strand',
    'label'    => $obj->seq_region_strand < 0 ? 'Reverse' : 'Forward'
  });
  if( $obj->analysis ) {
    $panel->add_entry({
      'type'     => 'Analysis',
      'label'    => $obj->analysis->display_label,
      'priority' => 2
    });
    $panel->add_entry({
      'label_html'    => $obj->analysis->description,
      'priority' => 1
    });
  }


## Protein coding transcripts only....
  return;
}

sub _ajax_zmenu_compara_tree_node{
  # Specific zmenu for compara tree nodes
  my $self = shift;
  my $panel = $self->_ajax_zmenu;
  my $obj = $self->object;

  my $collapse = $obj->param('collapse');
  my $node_id  = $obj->param('node') || die( "No node value in params" );
  my %collapsed_ids = map{$_=>1} grep{$_} split(',', $collapse);
  my $tree = $obj->get_ProteinTree || die( "No protein tree for gene" );
  my $node = $tree->find_node_by_node_id($node_id) 
      || die( "No node_id $node_id in ProteinTree" );
  
  my $tagvalues = $node->get_tagvalue_hash; 
  my $is_leaf = $node->is_leaf;
  my $leaf_count = scalar @{$node->get_all_leaves};
  my $parent_distance = $node->distance_to_parent || 0;

  # Caption
  my $taxon = $tagvalues->{'taxon_name'};
  if( ! $taxon  and $is_leaf ){
    $taxon = $node->genome_db->name;
  }
  $taxon ||= 'unknown';
  $panel->{'caption'} = "Taxon: $taxon";
  if( my $alias = $tagvalues->{'taxon_alias'} ){
    $panel->{'caption'} .= " ($alias)";
  }

  # Branch length
  $panel->add_entry({
    'type' => 'Branch_Length',
    'label' => $parent_distance,
    'priority' => 9,
  });

  # Bootstrap
  if( my $boot = $tagvalues->{'Bootstrap'} ){
    $panel->add_entry({
      'type' => 'Bootstrap',
      'label' => $boot,
      'priority' => 8,
    });
  }

  # Expand all nodes
  if( %collapsed_ids ){
    $panel->add_entry({
      'type'     => 'Image',
      'label'    => 'expand all sub-trees',
      'priority' => 4,
      'link'     => $obj->_url
          ({'type'     =>'Gene',
            'action'   =>'Compara_Tree',
            'collapse' => '' }),
        });
  }

  # Collapse other nodes
  my @adjacent_subtree_ids 
      = map{$_->node_id} @{$node->get_all_adjacent_subtrees};
  if( grep{ !$collapsed_ids{$_} } @adjacent_subtree_ids ){
    $panel->add_entry({
      'type'     => 'Image',
      'label'    => 'collapse other nodes',
      'priority' => 3,
      'link'     => $obj->_url
          ({'type'   =>'Gene',
            'action' =>'Compara_Tree',
            'collapse' => join( ',', 
                                (keys %collapsed_ids),
                                @adjacent_subtree_ids ) }), });
  }
  

  if( $is_leaf ){ # Leaf node
    # expand all paralogs
    my $gdb_id = $node->genome_db_id;
    my %collapse_nodes;
    my %expand_nodes;
    foreach my $leaf( @{$tree->get_all_leaves} ){
      if( $leaf->genome_db_id == $gdb_id ){
        foreach my $ancestor( @{$leaf->get_all_ancestors} ){
          $expand_nodes{$ancestor->node_id} = $ancestor;
        }
        foreach my $adjacent( @{$leaf->get_all_adjacent_subtrees} ){
          $collapse_nodes{$adjacent->node_id} = $adjacent;
        }
      }
    }
    my @collapse_node_ids = grep{! $expand_nodes{$_}} keys %collapse_nodes;
    if( @collapse_node_ids ){
      $panel->add_entry({
        'type'     => 'Image',
        'label'    => 'show all paralogs',
        'priority' => 5,
        'link'     => $obj->_url
            ({'type'     =>'Gene', 
              'action'   =>'Compara_Tree',
              'collapse' => join( ',', @collapse_node_ids ) }),
          }); 
    }
  }

  if( ! $is_leaf ){
    
    # Duplication confidence
    my $dup = $tagvalues->{'Duplication'};
    if( defined( $dup ) ){
      my $con = sprintf( "%.3f",
                         $tagvalues->{'duplication_confidence_score'} 
                         || $dup || 0 );
      $con = 'dubious' if $tagvalues->{'dubious_duplication'};
      $panel->add_entry({
        'type' => 'Type',
        'label' => ($dup ? "Duplication (confidence $con)" : 'Speciation' ),
        'priority' => 7,
      });
    }
    
    # Gene count
    $panel->add_entry({
      'type' => 'Gene_Count',
      'label' => $leaf_count,
      'priority' => 10,
    });

    # Expand this node
    if( $collapsed_ids{$node_id} ){
      $panel->add_entry({
        'type'     => 'Image',
        'label'    => 'expand this sub-tree',
        'priority' => 5,
        'link'     => $obj->_url
            ({'type'     =>'Gene', 
              'action'   =>'Compara_Tree',
              'collapse' => join( ',', 
                                  ( grep{$_ != $node_id} 
                                    keys %collapsed_ids ) ) }),
           });
    }

    # Collapse this node
    else {
      $panel->add_entry({
        'type'     => 'Image',
        'label'    => 'collapse this node',
        'priority' => 3,
        'link'     => $obj->_url
            ({'type'   =>'Gene',
              'action' =>'Compara_Tree',
              'collapse' => join( ',', $node_id, (keys %collapsed_ids) ) }),
          });
    }

    # Subtree dumps
    my( $url_align, $url_tree ) = $self->_dump_tree_as_text($node);

    $panel->add_entry({
      'type'      => 'View Sub-tree',
      'label'     => 'Tree: New Hampshire',
      'priority'  => 2,
      'link'      => $url_tree,
      'extra'     => {'external' => 1}, 
    });

    $panel->add_entry({
      'type'      => 'View Sub-tree',
      'label'     => 'Alignment: FASTA',
      'priority'  => 2,
      'link'      => $url_align,
      'extra'     => {'external' => 1},
    });

    # Jalview
    my $jalview_html 
        = $self->_compara_tree_jalview_html( $url_align, $url_tree );
    $panel->add_entry({
      'type'      => 'View Sub-tree',
      'label'     => '[Requires Java]',
      'label_html'=> $jalview_html,
      'priority'  => 1, } );
  }


  return;
}


sub _dump_tree_as_text{
  # Takes a compara tree and dumps the alignment and tree as text files.
  # Returns the urls of the files that contain the trees
  my $self = shift;
  my $tree = shift || die( "Need a ProteinTree object!" );

  # Establish some URL/file paths
  my $object = $self->object;
  my $defs   = $object->species_defs;
  my $temp_name = $object->temp_file_name( undef, 'XXX/X/X/XXXXXXXXXXXXXXX' );
  my $file_base = $defs->ENSEMBL_TMP_DIR_IMG . "/$temp_name";
  my $file_fa   = $file_base . '.fa.png'; # .png suffix until httpd.conf fixed
  my $file_nh   = $file_base . '.nh.png';
  my $url_site  = $defs->ENSEMBL_BASE_URL;
  my $url_base  = $url_site . $defs->ENSEMBL_TMP_URL_IMG . "/$temp_name";
  my $url_fa    = $url_base . '.fa.png';
  my $url_nh    = $url_base . '.nh.png';
  $object->make_directory( $file_base );

  # Write the fasta alignment using BioPerl
  my $format = 'fasta';
  my $align = $tree->get_SimpleAlign('','','','','',1);
  my $aio = Bio::AlignIO->new( -format => $format, -file => ">$file_fa" );
  $aio->write_aln( $align );

  #and nh files
  open( NH, ">$file_nh" ) or die( "Cannot open $file_nh for write: $!" );
  print( NH $tree->newick_format("full_web") );
  close NH; 

  return( $url_fa, $url_nh );

}

our $_JALVIEW_HTML_TMPL = qq(
<applet code="jalview.bin.JalviewLite"
       width="140" height="35"
       archive="%s/jalview/jalviewApplet.jar">
  <param name="file" value="%s">
  <param name="treeFile" value="%s">
  <param name="defaultColour" value="clustal">
</applet> );

sub _compara_tree_jalview_html{
  # Constructs the html needed to launch jalview for fasta and nh file urls
  my $self = shift;
  my $url_fa = shift;
  my $url_nh = shift;
  my $url_site  = $self->object->species_defs->ENSEMBL_BASE_URL;
  my $html = sprintf( $_JALVIEW_HTML_TMPL, $url_site, $url_fa, $url_nh );
  return $html;
}

sub _ajax_zmenu_regulation {
  my ($self, $panel ) = @_;
  my $obj = $self->object;
  my $params = $obj->[1]->{'_input'}; warn $params->{'caption'}[0];
  $panel->{'caption'} = $params->{'caption'}[0];
  my $link = $params->{$obj->type}[0];
  my $species = $obj->species_defs->species;

  foreach my $p (keys %{$params}){
    if ($p =~/^\d+/){
      my $value = $params->{$p}[0];
      my ($priority, $type) = split(/:/, $p);
      my $link;
      if ($type =~/location/i){
        $link = $obj->_url({'type'=>'Location','action'=>'View','r'=>$value});
      } elsif ($type =~/Analysis/i && $value =~/cisred/i){
          my $cis_red;
          if ($species=~/Homo_sapiens/){ $cis_red = "http://www.cisred.org/human9/gene_view?ensembl_id=";}
          elsif ( $species =~/Mus_musculus/) { $cis_red = "http://www.cisred.org/mouse4/gene_view?ensembl_id=";}
          $link = $cis_red . $obj->stable_id;
      } elsif ($type =~ /Associated/i){
          if ($type =~/gene/i){ $link = $obj->_url({'type'=>'Gene','action'=>'Summary','g'=>$value});}
          elsif ($type =~/transcript/i) {$link = $obj->_url({'type'=>'Transcript','action'=>'Summary','t'=>$value}); }        } elsif ( $type =~/factor/i){
          $link = $link = $obj->_url({'type'=>'Location','View'=>'Karyotype','feat_type'=>'RegulatoryFeature','id'=>$value}); 
      }
       

      $panel->add_entry({
        'type'     =>  $type,
        'label'    =>  $value,
        'priority' =>  $priority,
        'link'     =>  $link,
      });

    }
  }
  return;
}

sub _ajax_zmenu_id_history_tree {
  my ($self, $panel ) = @_; 
  my $obj = $self->object;
  my $params = $obj->[1]->{'_input'}; warn $params->{'caption'}[0];
  $panel->{'caption'} = $params->{'caption'}[0];
  my $link = $params->{$obj->type}[0];

  foreach my $p (keys %{$params}){
    if ($p =~/^\d+/){ 
      my $value = $params->{$p}[0];
      my ($priority, $type) = split(/:/, $p);
 
      $panel->add_entry({
        'type'     =>  $type,
        'label'    =>  $value,
        'priority' =>  $priority,
        'link'     =>  $link,
      });
    }
  }
  return;
}

sub local_context  { return $_[0]->_local_context;  }
sub local_tools    { return $_[0]->_local_tools;    }
sub content_panel  { return $_[0]->_content_panel;  }
sub context_panel  { return $_[0]->_context_panel;  }

sub geneseqview {
  my $self   = shift;
  $self->set_title( "Gene sequence for ".$self->{object}->stable_id );
  if( my $panel1 = $self->new_panel( 'Information',
    'code'    => "info#",
    'caption' => 'Gene Sequence information for '.$self->{object}->stable_id,
  ) ) {
    $panel1->add_components(qw(
      name           EnsEMBL::Web::Component::Gene::name
      location       EnsEMBL::Web::Component::Gene::location
      markup_options EnsEMBL::Web::Component::Gene::markup_options
      sequence       EnsEMBL::Web::Component::Slice::sequence_display
    ));
    $self->add_panel( $panel1 );
  }
}

sub geneseqalignview {
  my $self   = shift;
  $self->set_title( "Gene sequence for ".$self->{object}->stable_id );
  if( my $panel1 = $self->new_panel( 'Information',
    'code'    => "info#",
    'caption' => 'Gene Sequence information for '.$self->{object}->stable_id,
  ) ) {
    $panel1->add_components(qw(
      name           EnsEMBL::Web::Component::Gene::name
      location       EnsEMBL::Web::Component::Gene::location
      markup_options EnsEMBL::Web::Component::Gene::markup_options
      sequence       EnsEMBL::Web::Component::Slice::align_sequence_display
    ));
    $self->add_panel( $panel1 );
  }
}


sub sequencealignview {

  ### Calls methods in component to build the page
  ### Returns nothing

  my $self   = shift;
  my $strain =  $self->{object}->species_defs->translate( "strain" );
  $self->set_title( "Gene sequence for ".$self->{object}->stable_id );
  if( my $panel1 = $self->new_panel( 'Information',
    'code'    => "info#",
    #'null_data' => "<p>No $strain data for this gene.</p>",
   'caption' => 'Gene Sequence information for '.$self->{object}->stable_id,
  ) ) {
    $panel1->add_components(qw(
     name           EnsEMBL::Web::Component::Gene::name
      location       EnsEMBL::Web::Component::Gene::location
      markup_options EnsEMBL::Web::Component::Gene::markup_options
      sequence       EnsEMBL::Web::Component::Slice::sequencealignview
    ));
   $self->add_panel( $panel1 );
  }
}


1;
