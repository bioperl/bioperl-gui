package PhysicalMapStrip;

use Bio::Seq;
use Bio::Tools::CodonTable;

use FeatureWidget;
use PaintDevice;

use strict;

sub new {
    my $class = shift;
    my $self = {};
    
    $self->{startbase}=shift;
    $self->{endbase}=shift; 

    $self->{x_start}=shift;
    if (!defined($self->{x_start})) {
	$self->{x_start}=0;
    }

    $self->{y_start}=shift;
    if (!defined($self->{y_start})) {
	$self->{y_start}=0;
    }

    $self->{x_scale}=shift;
    if (!defined($self->{x_scale})) {
	$self->{x_scale}=1;
    }

    $self->{y_scale}=shift;
    if (!defined($self->{y_scale})) {
	$self->{y_scale}=1;
    }

    $self->{featurewidgets}= [];

    return $self;
}

sub add_feature_widget {
    my $self=shift;
    my $widget=shift;
    push @{$self->{featurewidgets}},$widget;
}

sub get_bounds {
    my $self=shift;
    return ($self->{startbase},$self->{endbase});
}

sub draw {
    my $self=shift;
    my $paintdevice=shift;
    for (my $i=0;$i<@{$self->{featurewidgets}};$i++) {
	$self->{featurewidgets}->[$i]->draw($self,$paintdevice);
    }
}

sub height_in_lines {
    return 1;
}

sub name {
    return 'PhysicalWidgetStrip';
}

sub offset {
    my $self=shift;
    my $x_start=shift;
    if (defined $x_start) {
	$self->{x_start}=$x_start;
	$self->{y_start}=shift;
    } else {
	return ($self->{x_start},$self->{y_start});
    }
}
sub scale {
    my $self=shift;
    my $x_scale=shift;
    if (defined $x_scale) {
	$self->{x_scale}=$x_scale;
	$self->{y_scale}=shift;
    } else {
	return ($self->{x_scale},$self->{y_scale});
    }
}



package AxisStrip;
@AxisStrip::ISA=qw( PhysicalMapStrip );

sub new {
    my $class = shift;
    my $self = new PhysicalMapStrip(@_);

    $self->{tick_interval}=compute_tick_interval($self->{startbase},
						 $self->{endbase});

    bless $self,$class;

    return $self;
}

sub compute_tick_interval {
    my $start=shift;
    my $end=shift;
    my $range=$end-$start;
    my $logrange=int((log($range)/log(10))+0.5);
    
    return 10**($logrange-1);

}

sub draw {
    my $self = shift;
    my $paintdevice = shift;
    my $x_scale=$self->{x_scale};
    my $y_scale=$self->{y_scale};
    my $x_start=$self->{x_start};
    my $y_start=$self->{y_start};

    my $startbase=reverse $self->{startbase};
    $startbase =~ s/(\d{3})/$1 /g;
    $startbase=reverse $startbase;
    $startbase =~ s/^\s+//;

    my $endbase=reverse $self->{endbase};
    $endbase =~ s/(\d{3})/$1 /g;
    $endbase=reverse $endbase;
    $endbase =~ s/^\s+//;

    
    $paintdevice->add_line($x_start,$y_start+0.5*$y_scale,
			   $x_start+1*$x_scale,$y_start+0.5*$y_scale);
    $paintdevice->add_text($x_start,$y_start+0.47*$y_scale,
			   $startbase,'halign'=>'left','valign'=>'bottom');
    $paintdevice->add_text($x_start+1.0*$x_scale,$y_start+0.47*$y_scale,
			   $endbase,'halign'=>'right','valign'=>'bottom');
    $paintdevice->add_line($x_start,$y_start+0.48*$y_scale,
			   $x_start,$y_start+0.52*$y_scale);
    $paintdevice->add_line($x_start+1.0*$x_scale,$y_start+0.48*$y_scale,
			   $x_start+1.0*$x_scale,$y_start+0.52*$y_scale);
    my $tick_start=int($self->{startbase}/$self->{tick_interval})+1;
    $tick_start*=$self->{tick_interval};
    my $tick_end=int($self->{endbase}/$self->{tick_interval});
    $tick_end*=$self->{tick_interval};

    my $x_position;
    for (my $i=$tick_start;$i<=$tick_end;$i+=$self->{tick_interval}) {
	$x_position=($i-$self->{startbase})/
	    ($self->{endbase}-$self->{startbase});
	$paintdevice->add_line($x_start+$x_position*$x_scale,
			       $y_start+0.48*$y_scale,
			       $x_start+$x_position*$x_scale,
			       $y_start+0.52*$y_scale);
    }

    $self->PhysicalMapStrip::draw($paintdevice);
}

sub height_in_lines {
    return 3;
}

sub name {
    return 'AxisStrip';
}

package SequenceStrip;
@SequenceStrip::ISA=qw( PhysicalMapStrip );

%SequenceStrip::REVCOMS=('A'=>'T',
			 'T'=> 'A',
			 'G'=>'C',
			 'C'=>'G');
sub new {
    my $class = shift;
    my $map=shift;
    my $self = new PhysicalMapStrip(@_);

    $self->{map}=$map;
    $self->{seqobj}=$map->get_seqobj;

    bless $self,$class;

    return $self;
}

sub draw {
    my $self = shift;
    my $paintdevice = shift;
    my $x_scale=$self->{x_scale};
    my $y_scale=$self->{y_scale};
    my $x_start=$self->{x_start};
    my $y_start=$self->{y_start};


    my $x_position;
    my $y_position_fwd=$y_start+0.10*$y_scale;
    my $y_position_rev=$y_start+0.50*$y_scale;
    my $startbase=$self->{startbase};
    my $endbase=$self->{endbase};
    my ($minbase,$maxbase)=$self->{map}->get_bounds();
    $startbase=$minbase
	if ($startbase<$minbase);
    $endbase=$maxbase
	if ($endbase>$maxbase);
    if ($startbase>0 && $endbase>0 && $endbase>$startbase) {
	my $subseq=$self->{seqobj}->subseq($startbase,$endbase);
	for (my $i=$startbase;$i<=$endbase;$i++) {
	    my $letter_fwd=uc substr $subseq,($i-$startbase),1;
	    my $letter_rev=$SequenceStrip::REVCOMS{$letter_fwd};
	    $x_position=($i-$self->{startbase})/
		($self->{endbase}-$self->{startbase});
	    $paintdevice->add_text($x_start+$x_position*$x_scale,
				   $y_position_fwd,
				   $letter_fwd,
				   'halign'=>'middle',
				   'valign'=>'top');
	    $paintdevice->add_text($x_start+$x_position*$x_scale,
				   $y_position_rev,
				   $letter_rev,
				   'halign'=>'middle',
				   'valign'=>'top');
	}
	$self->PhysicalMapStrip::draw($paintdevice);
    }
}

sub height_in_lines {
    return 3;
}

sub name {
    return 'SequenceStrip';
}

package ScalableStrip;

@ScalableStrip::ISA = qw( PhysicalMapStrip );

sub new {
    my $class = shift;
    my $self = new PhysicalMapStrip(@_);

    bless $self,$class;

    return $self;

}

sub height_in_lines {
    return 4;
}

sub name {
    return 'ScalableStrip';
}


package FeatureStrip;

use strict;

@FeatureStrip::ISA=qw(ScalableStrip);

sub new {
    my $class=shift;
    my $map=shift;
    my $self=new ScalableStrip(@_);

    $self->{map}=$map;
    $self->{seqobj}=$map->get_seqobj();
    $self->{residues_visisble}=0;
    $self->{codontable}=new Bio::Tools::CodonTable();

    bless $self,$class;

    return $self;

}

sub draw {
    my $self=shift;
    my $paintdevice=shift;

    my $x_start=$self->{x_start};
    my $y_start=$self->{y_start};
    my $x_scale=$self->{x_scale};
    my $y_scale=$self->{y_scale};
    my $startbase=$self->{startbase};
    my $endbase=$self->{endbase};
    my $basespan=$endbase-$startbase+1;

    $paintdevice->color_alloc('lightgrey',0.8,0.8,0.8)
	if (!$paintdevice->color_defined('lightgrey'));
    
    if (ScalableFeatureWidget::are_frames_visible() && 
	$basespan>$PhysicalMapWidget::sequence_display_threshold) {
	foreach my $frame (0..5) {
	    my $y_line=$ScalableFeatureWidget::positions[$frame];
	    $paintdevice->add_line($x_start,
				   $y_start+$y_line*$y_scale,
				   $x_start+$x_scale,
				   $y_start+$y_line*$y_scale,
				   'color'=>'lightgrey');
	}
    }

    $self->ScalableStrip::draw($paintdevice);

    if (ScalableFeatureWidget::are_frames_visible() && 
	$basespan <= $PhysicalMapWidget::sequence_display_threshold) {
	my ($minbase,$maxbase)=$self->{map}->get_bounds();
	$startbase=$minbase
	    if ($startbase<$minbase);
	$endbase=$maxbase
	    if ($endbase>$maxbase);
	if ($startbase>0 && $endbase>0 && $endbase>$startbase) {
	    my $subseq=$self->{seqobj}->subseq($startbase,$endbase);
	    for (my $i=$startbase;$i<=$endbase-2;$i++) {
		my $frame_direct=($i-1)%3;
		my $frame_rev=$frame_direct+3;
		my $codon=uc substr $subseq,($i-$startbase),3;
		my $x_position=($i-$self->{startbase}+1)/
		    ($self->{endbase}-$self->{startbase});
		foreach my $frame (($frame_direct,$frame_rev)) {
		    my $y_pos=$ScalableFeatureWidget::positions[$frame];
		    if ($frame>2) {
			my $revcodon=reverse $codon;
			$codon='';
			foreach my $letter (split(//,$revcodon)) {
			    $codon.=$SequenceStrip::REVCOMS{$letter};
			}
		    }
		    my $residue=$self->{codontable}->translate($codon);
		    my $color='black';
		    $color='red'
			if ($residue eq '*');
		    $paintdevice->add_text($x_start+$x_position*$x_scale,
					   $y_start+$y_pos*$y_scale,
					   $residue,
					   'color'=>$color,
					   'halign'=>'middle',
					   'valign'=>'middle');
		}
	    }
	}
    }

}

sub height_in_lines {

    return 11
	if (ScalableFeatureWidget::are_frames_visible() &&
	    !ScalableFeatureWidget::are_strands_collapsed());

    return 7
	if (ScalableFeatureWidget::are_frames_visible() &&
	    ScalableFeatureWidget::are_strands_collapsed());

    return 4
	if (!ScalableFeatureWidget::are_frames_visible() &&
	    !ScalableFeatureWidget::are_strands_collapsed());

    return 3;
}

sub name {
    return 'FeatureStrip';
}

1

__END__

=head1


=cut
