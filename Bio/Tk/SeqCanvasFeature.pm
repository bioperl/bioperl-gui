=head1 SeqCanvasFeature.pm

=head2 AUTHORS

Mark Wilkinson (mwilkinson@gene.pbi.nrc.ca)
Plant Biotechnology Institute, National Research Council of Canada.
Copyright (c) National Research Council of Canada, April, 2001.

=head2 DISCLAIMER

Anyone who intends to use and uses this software and code acknowledges and
agrees to the following: The National Research Council of Canada (herein "NRC")
disclaims any warranties, expressed, implied, or statutory, of any kind or
nature with respect to the software, including without limitation any warranty
or merchantability or fitness for a particular purpose.  NRC shall not be liable
in any event for any damages, whether direct or indirect,
consequential or incidental, arising from the use of the software.

=head2 SYNOPSIS

Should not be used (and really has no use) outside of SeqCanvas.


=head2 DESCRIPTION and ACKNOWLEDGEMENTS

Essentially, SeqCanvasFeatures encapsulate all the things
that SeqCanvas needs to know about a feature in order to map it.  This includes both
the BioPerl feature itself, as well as the offset, and colour.

In addition, SeqCanvasFeature has the ability to rip itself apart into its constituent
transcripts and exons (if present).  Thus there are only two types of SCF's:  'Gene', and
'Generic'.  "generic" features are alawys called by a simple ->_draw.  "Gene" features
are pulled apart with sub-features created on-the-fly in this module, and then mapped onto
both the finished and draft canvas.


=head2 CONTACT

Mark Wilkinson (mwilkinson@gene.pbi.nrc.ca)

=cut


package Bio::Tk::SeqCanvasFeature;

use strict;
use Carp;
use vars qw($AUTOLOAD);

{
	#Encapsulated class data
	
	#___________________________________________________________
	#ATTRIBUTES
    my %_attr_data = #     				DEFAULT    	ACCESSIBILITY
                  (
                  	SeqCanvas	=>  [undef, 	'read/write'],
                  	Feature 	=>	[undef, 	'read/write'],		# the actual bioperl Feature object
                  	offset		=>	[undef,		'read/write'],		# offset from whichever axis it is mapped to
                  	color		=>	[undef, 	'read/write'],		# duh
                  	canvas_name	=>	[undef, 	'read/write'],	# draft or finished
                  	canvas		=>	[undef, 	'read/write'],	# the canvas widget reference
                  	map			=>	[undef, 	'read/write'],	# the map widget reference
                  	widget		=>	[undef, 	'read/write'],		# the widget itself
                  	FID			=>	[undef,  'read/write'],			# the FeatureID, which is the position of that feature in the list of mapped features.
                  	label		=>  [undef,  'read/write'], 		# which tag should be used as the label fo the mapped widget                 	
                    tags		=>  [[], 	'read/write'],
                    transcript_color => ["#dddddd",  'read/write'], # transcripts are grey
                    parent_transcript=>  [undef,  'read/write'],  # sub-gene objects need to know their parent transcript
                    parent_gene		=>  [undef,  'read/write'],  # sub-gene objects need to know their parent gene

                    );

   #_____________________________________________________________
    #METHODS, to operate on encapsulated class data
    my $_nextid;
    # Is a specified object attribute accessible in a given mode
    sub _accessible  {
	my ($self, $attr, $mode) = @_;
	$_attr_data{$attr}[1] =~ /$mode/
    }

    # Classwide default value for a specified object attribute
    sub _default_for {
	my ($self, $attr) = @_;
	$_attr_data{$attr}[0];
    }

    # List of names of all specified object attributes
    sub _standard_keys {
	keys %_attr_data;
    }

    sub next_id {
		unless ($_nextid){$_nextid = 0}
		return $_nextid++;
    }
}

sub AUTOLOAD {
    no strict "refs";
    my ($self, $newval) = @_;

    $AUTOLOAD =~ /.*::(\w+)/;

    my $attr=$1;
    if ($self->_accessible($attr,'write')) {

	*{$AUTOLOAD} = sub {
	    if (defined $_[1]) { $_[0]->{$attr} = $_[1] }
	    return $_[0]->{$attr};
	};    ### end of created subroutine

###  this is called first time only
	if (defined $newval) {
	    $self->{$attr} = $newval
	}
	return $self->{$attr};

    } elsif ($self->_accessible($attr,'read')) {

	*{$AUTOLOAD} = sub {
	    return $_[0]->{$attr} }; ### end of created subroutine
	return $self->{$attr}  }


    # Must have been a mistake then...
    croak "No such method: $AUTOLOAD";
}


sub new {
	my ($caller, %args) = @_;
	
	my $caller_is_obj = ref($caller);
    my $class = $caller_is_obj || $caller;

    my $self = bless {}, $class;

    foreach my $attrname ( $self->_standard_keys ) {
    	if (exists $args{$attrname}) {
		$self->{$attrname} = $args{$attrname} }
    elsif ($caller_is_obj) {
		$self->{$attrname} = $caller->{$attrname} }
    else {
		$self->{$attrname} = $self->_default_for($attrname) }
    }
    my $id = $self->next_id;
    $self->FID("FID$id");
    return $self;

}

sub drawThyself {
	my ($self, @tags) = @_;
   	my ($genes, $transcripts, $exons, $promotors, $polyAs);
   	my $map = $self->canvas_name;
   	if ($map eq "draft"){$self->_drawThyselfOnDraft}
   	else {($genes, $transcripts, $exons, $promotors, $polyAs) = $self->_drawThyselfOnFinished}  # this is necessary because the finished canvas must unpack the
   													# feature object and draw its transcripts        	
	return ($genes, $transcripts, $exons, $promotors, $polyAs);  # for draft objects, these are all empty
}

sub _drawThyselfOnDraft {
	my ($self) = @_;
	# draft features know enough about themselves to draw directly with no further parsing.
	$self->_draw;  # this both draws the widget, and encapsulates the widget into the SCF object
}


sub _drawThyselfOnFinished {
    my ($SCF_GENE) = @_;
    # SeqCanvasFeatures coming into this routine should be exclusively one of the following:
    # primary_tag = "gene"
    # $feature->can('transcripts')  ----> i.e. a GeneStructureI compliant feature
    # they do NOT have a color,
    # nor do they have an offset yet.
    # they must be 'unpacked' into their constituent parts, transcripts, exons, etc. and then mapped
	
    my $SeqCanvas = $SCF_GENE->SeqCanvas; # this is the parent window into which we are mapping this widget
    # which is needed to get color and offset information
    my (@genes, @transcripts, @exons, @promotors, @polyAs, @blank_transcripts);
	
    push @genes, $SCF_GENE;	# put top-level gene SCF into the list of mapped objects that will be passed back for binding

    # starting with the highest level object - the entire gene
    $SCF_GENE->offset($SeqCanvas->current_offsets->{"gene"}); # assign standard colors and offsets
    $SCF_GENE->color($SeqCanvas->current_colors->{"gene"});
    #  DRAW GENE-LEVEL OBJECT
    $SCF_GENE->_draw;		# this also encapsulates the widget itself into the SCF object

    #FIND TRANSCRIPT OBJECTS
    if ($SCF_GENE->Feature->can("transcripts")) { # don't do the rest of this routine if it is not a GeneStructureI compliant object.
	my $model = 0;		# ordinal number of transcript (needed for offset calculation)
	foreach my $transcript ($SCF_GENE->Feature->transcripts) { # take each transcript
	    ++$model;
		
		my $SCF_transcript = Bio::Tk::SeqCanvasFeature->new(	SeqCanvas => $SeqCanvas,
									Feature => $transcript,	# this fills all of the FeatureI methods
									canvas_name => 'finished',
									canvas => $SeqCanvas->FinishedCanvas,
									map => $SeqCanvas->FinishedMap,
									label => $SeqCanvas->label,
							       ); # create a new SeqcanvasFeature object for this feature
	    # it is assigned an FID during creation
	    $SCF_transcript->offset($SeqCanvas->current_offsets->{"transcript$model"}); # assign standard color and offset according to ordinal number
	    $SCF_transcript->color($SCF_transcript->transcript_color); # get the transcript default color
	    $SCF_transcript->_draw;
        $SCF_transcript->parent_gene($SCF_GENE);
        push @transcripts, $SCF_transcript;
			
	    foreach my $exon ($transcript->exons) {
			
			my $SCF = Bio::Tk::SeqCanvasFeature->new(	SeqCanvas => $SeqCanvas,
									Feature => $exon, # this fills all of the FeatureI methods
									canvas_name => 'finished',
									canvas => $SeqCanvas->FinishedCanvas,
									map => $SeqCanvas->FinishedMap,
									label => $SeqCanvas->label,
								); # create a new SeqcanvasFeature object for this feature
			# it is assigned an FID during creation
			$SCF->offset($SeqCanvas->current_offsets->{"transcript$model"}); # assign standard offset according to ordinal number
			$SCF->color($SeqCanvas->current_colors->{$SCF->source}); # assign color according to the source tag
			$SCF->_draw;
			$SCF->parent_gene($SCF_GENE);
			$SCF->parent_transcript($SCF_transcript);
			
			push @exons, $SCF;		
	    }
	    foreach my $promotor ($transcript->promoters) {
			my $SCF = Bio::Tk::SeqCanvasFeature->new(	SeqCanvas => $SeqCanvas,
									Feature => $promotor, # this fills all of the FeatureI methods
									canvas_name => 'finished',
									canvas => $SeqCanvas->FinishedCanvas,
									map => $SeqCanvas->FinishedMap,
									label => $SeqCanvas->label,
								); # create a new SeqcanvasFeature object for this feature
			# it is assigned an FID during creation
			$SCF->offset($SeqCanvas->current_offsets->{"transcript$model"}); # assign standard offset according to ordinal number
			$SCF->color($SeqCanvas->current_colors->{$SCF->source}); # assign color by source tag
			$SCF->_draw;
			$SCF->parent_gene($SCF_GENE);
					$SCF->parent_transcript($SCF_transcript);
					push @promotors, $SCF;
	    }
	    if ($transcript->poly_A_site) {
		my $polyA = $transcript->poly_A_site;
		my $SCF = Bio::Tk::SeqCanvasFeature->new(	SeqCanvas => $SeqCanvas,
								Feature => $polyA, # this fills all of the FeatureI methods
								canvas_name => 'finished',
								canvas => $SeqCanvas->FinishedCanvas,
								map => $SeqCanvas->FinishedMap,
								label => $SeqCanvas->label,
							); # create a new SeqcanvasFeature object for this feature
		# it is assigned an FID during creation
		$SCF->offset($SeqCanvas->current_offsets->{"transcript$model"}); # assign standard offset according to ordinal number
		$SCF->color($SeqCanvas->current_colors->{$SCF->source}); # assign color by source tag
		$SCF->_draw;
		$SCF->parent_gene($SCF_GENE);
            	$SCF->parent_transcript($SCF_transcript);
            	push @polyAs, $SCF;
				
	    }	
	}			# end of foreach my transcripts
    }				# end of if self can transripts

    return (\@genes, \@transcripts, \@exons, \@promotors, \@polyAs);		
}


sub _draw {
	my ($self) = @_;
	my $map = $self->map;
	my $canvas = $self->canvas;
	my $FID = $self->FID;
	my $color = $self->color;
	my $label;
	if ($self->has_tag($self->label)){
	    if ($self->Feature->strand == -1) {
		$self->offset($self->offset - 5);
	    }
	    ($label) = ($self->label)?$self->each_tag_value($self->label):undef;  # set the label if it is required and present
	} else {
	    $label = undef;
	}
	my $offset = $self->offset;
	my $start = $self->start;
	my $end = $self->end;
	my $strand = $self->strand;
	my @tags = $self->_parse_feature_info;
	my @coords; my $widget;

	if ($strand =~ /\-/) {
		push @coords, [$end, $start];
		if (!$label){         # if no labels, or if this feature doesn't have the label then map without labelling
			$widget = $map->MapObject(\@coords, '-ataxis' => $offset,
							'-color' => $color, '-tags' => \@tags);
		} else {
			$widget = $map->MapObject(\@coords, '-ataxis' => $offset, '-label' => $label, '-labelcolor' => $color,
							'-color' => $color, '-tags' => \@tags);
		}
				
	} else {
		push @coords, [$start, $end];
		if (!$label){
			$widget = $map->MapObject(\@coords, '-ataxis' => -$offset,
							'-color' => $color, '-tags' => \@tags);
		} else {
			$widget = $map->MapObject(\@coords, '-ataxis' => -$offset, '-label' => $label, '-labelcolor' => $color,
							'-color' => $color, '-tags' => \@tags);
		}
	}
	$self->widget($widget);	# dont forget to put a reference to the widget itself into the SCF		
	}
			
sub _parse_feature_info {
	my ($self) = @_;
	my @tags;
	my $start = $self->start;
	my $stop = $self->end;
	my $offset = $self->offset;
	my $source = $self->source_tag;
    my $type = $self->primary_tag;
    my $strand = $self->strand;
    my $whichmap = $self->canvas_name;
	my $ObjectType = ref($self->Feature);
    my $FID = $self->FID;
    $strand =~ s/\+/1/;                     # these change GFF format strand designations into BioPerl Seq object strand desig.
    $strand =~ s/-$/-1/;                    # But really... BioPerl should adopt GFF formats one day -  The GFF designations are
    $strand =~ s/\./0/;	                    # much more intuitive (IMHO)
    if ($self->has_tag("id")){push @tags, "DB_ID " . $self->each_tag_value("id")}  # this is to 'link' this widget to an an external database if desired.
    push @tags, $FID;	# assign that ID to this on-screen widget		
    push @tags, "Source $source";           # push the source so that we can retrieve the offset and color later if necessary
    push @tags, "Strand $strand";
    push @tags, "Type $type";				# this holds the info about what type of Feature it is... comes from Primary tag...
    push @tags, "Canvas $whichmap";			# let the widget know which map it is sitting on
    push @tags, "_SC_start $start";
    push @tags, "_SC_stop $stop";
    push @tags, "_SC_offset $offset";
	push @tags, "ObjectType $ObjectType";
    push @tags, "M_Ftr";					# this is a generic tag to indicate that this is a mapped feature - used to obtain the bounding box for mapped features which then sets the scrollregion
    return (@tags);  
}



# for partial SeqFeatureI compatability
sub start {
	my ($self) = @_;
	return $self->Feature->start;
}

sub end {
	my ($self) = @_;
	return $self->Feature->end;
}

sub stop {
	my ($self) = @_;
	return $self->Feature->end;
}

sub source {
	my ($self) = @_;
	return $self->Feature->source_tag;
}

sub source_tag {
	my ($self) = @_;
	return $self->Feature->source_tag;
}

sub primary_tag {
	my ($self) = @_;
	return $self->Feature->primary_tag;
}

sub location {
	my ($self) = @_;
	return $self->Feature->location;
}

sub length {
	my ($self) = @_;
	return $self->Feature->length;
}

sub strand {
	my ($self) = @_;
	return $self->Feature->strand;
}

sub score {
	my ($self) = @_;
	return $self->Feature->score;
}

sub frame {
	my ($self) = @_;
	return $self->Feature->frame;
}

sub sub_SeqFeature {
	my ($self) = @_;
	return $self->Feature->sub_SeqFeature;
}

sub has_tag {
	my ($self, $tag) = @_;
	return $self->Feature->has_tag($tag);
}
	
sub each_tag_value {
	my ($self, $tag) = @_;
	return $self->Feature->each_tag_value($tag);
}

sub all_tags {
	my ($self) = @_;
	return $self->Feature->all_tags;
}

sub gff_string {
	my ($self, $format) = @_;
	return $self->Feature->gff_string($format);
}

	
1;
