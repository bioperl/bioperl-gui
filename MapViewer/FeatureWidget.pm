# 	$Id$	
        
package FeatureWidget;

use strict;

use PaintDevice;
use PhysicalMapStrip;


sub _new {
    my $class = shift;
    my $self = {};
    $self->{type}=shift;
    $self->{feature}=shift;

    bless $self,$class;

    return $self;
}

sub type {
    my $self = shift;
    return $self->{type};
}

package PositionalFeatureWidget;

use strict;

@PositionalFeatureWidget::ISA=qw(FeatureWidget);

sub _new {
    my $class = shift;
    my $feature=shift;
    my $self = _new FeatureWidget('positional',$feature);
    
    $self->{color}=shift;

    bless $self,$class;

    my ($left,$right)=($feature->start,$feature->end);

    $self->{position}=$left;
    $self->{orientation}=-1;
    if ($feature->strand == -1) {
	$self->{position}=$right;
	$self->{orientation}=1;
    }

    return $self;
}

sub _draw {
    my $self=shift;
    my $strip=shift;
    my $paintdevice = shift;


    my ($startbase,$endbase)=$strip->get_bounds();
    my ($x_scale,$y_scale)=$strip->scale;
    my ($x_start,$y_start)=$strip->offset;

    my $draw_position=($self->{position}-$startbase)/($endbase-$startbase);

    if ($draw_position>=0 && $draw_position<=1) {
	$paintdevice->add_line($x_start+$x_scale*$draw_position,
			       $y_start+0.5*$y_scale,
			       $x_start+$x_scale*$draw_position,
			       $y_start+(0.5+$self->{orientation}*0.15)*
			       $y_scale,
			       'color'=>$self->{color});
    }
}

package PromoterWidget;

use strict;

@PromoterWidget::ISA=qw(PositionalFeatureWidget);

sub new {
    my $class = shift;
    my $feature = shift;
    my $self = _new PositionalFeatureWidget $feature,'black';

    bless $self,$class;

    return $self;
}

sub draw {
    my $self=shift;
    my $strip=shift;
    my $paintdevice = shift;

    my ($startbase,$endbase)=$strip->get_bounds();
    my ($x_scale,$y_scale)=$strip->scale;
    my ($x_start,$y_start)=$strip->offset;

    my $draw_position_start=($self->{position}-$startbase)/
	($endbase-$startbase);
    my $draw_position_end=($self->{position}-$startbase)/
	($endbase-$startbase)+0.02;
    
    my $draw_position_middle=($self->{position}-$startbase)/
	($endbase-$startbase)+0.01;

    if ($self->{feature}->strand == -1) {
	$draw_position_end-=0.04;
	$draw_position_middle-=0.02;
    }

    if ($draw_position_start>=0 && $draw_position_start<=1) {
	$paintdevice->add_line($x_start+$x_scale*$draw_position_start,
			       $y_start+0.5*$y_scale,
			       $x_start+$x_scale*$draw_position_start,
			       $y_start+(0.5+$self->{orientation}*0.15)*
			       $y_scale,
			       'color'=>$self->{color});
	$paintdevice->add_line($x_start+$x_scale*$draw_position_start,
			       $y_start+(0.5+0.15*$self->{orientation})*
			       $y_scale,
			       $x_start+$x_scale*$draw_position_middle,
			       $y_start+(0.5+0.15*$self->{orientation})*
			       $y_scale,
			       'color'=>$self->{color});
	$paintdevice->add_line($x_start+$x_scale*$draw_position_middle,
			       $y_start+(0.5+0.25*$self->{orientation})*
			       $y_scale,
			       $x_start+$x_scale*$draw_position_middle,
			       $y_start+(0.5+0.05*$self->{orientation})*
			       $y_scale,
			       'color'=>$self->{color});
	$paintdevice->add_line($x_start+$x_scale*$draw_position_middle,
			       $y_start+(0.5+0.25*$self->{orientation})*
			       $y_scale,
			       $x_start+$x_scale*$draw_position_end,
			       $y_start+(0.5+0.15*$self->{orientation})*
			       $y_scale,
			       'color'=>$self->{color});
	$paintdevice->add_line($x_start+$x_scale*$draw_position_end,
			       $y_start+(0.5+0.15*$self->{orientation})*
			       $y_scale,
			       $x_start+$x_scale*$draw_position_middle,
			       $y_start+(0.5+0.05*$self->{orientation})*
			       $y_scale,
			       'color'=>$self->{color});
    }


    $paintdevice->add_reactive_zone($x_start+$x_scale*$draw_position_start,
				    $y_start+$y_scale*0.5,
				    $x_start+$x_scale*$draw_position_end,
				    $y_start+$y_scale*(0.5+0.25*$self->{orientation}),
				    $self->{feature})

	if ($paintdevice->type() eq 'reactive');

}


package TerminatorWidget;

use strict;

@TerminatorWidget::ISA=qw(PositionalFeatureWidget);

sub new {
    my $class = shift;
    my $feature = shift;
    my $self = _new PositionalFeatureWidget $feature,'red';

    bless $self,$class;

    return $self;
}
sub draw {
    my $self=shift;
    my $strip=shift;
    my $paintdevice = shift;

    $self->PositionalFeatureWidget::_draw($strip,$paintdevice);
    my ($startbase,$endbase)=$strip->get_bounds();
    my ($x_scale,$y_scale)=$strip->scale;
    my ($x_start,$y_start)=$strip->offset;

    my $draw_position=($self->{position}-$startbase)/($endbase-$startbase);

    if ($draw_position>=0 && $draw_position<=1) {
	$paintdevice->add_circle($x_start+$x_scale*$draw_position,
				 $y_start+(0.5+0.25*$self->{orientation})*
				 $y_scale,
				 0.1*$y_scale,
				 'color'=>$self->{color});
    }

    $paintdevice->add_reactive_zone($x_start+$x_scale*$draw_position
				    -0.05*$y_scale,
				    $y_start+(0.5+0.2*$self->{orientation})*$y_scale,
				    $x_start+$x_scale*$draw_position
				    +0.05*$y_scale,
				    $y_start+(0.5+0.3*$self->{orientation})*$y_scale,
				    $self->{feature})

	if ($paintdevice->type() eq 'reactive');

}

package ScalableFeatureWidget;

use strict;

@ScalableFeatureWidget::ISA=qw( FeatureWidget);

$ScalableFeatureWidget::display_threshold=0.05;

@ScalableFeatureWidget::positions=();

sub show_frames {
    $ScalableFeatureWidget::frames_visible=1;
    if (!$ScalableFeatureWidget::strands_collapsed) {
	@ScalableFeatureWidget::positions=(0.15, 0.25, 0.35, 0.45, 0.55, 0.65);
	$ScalableFeatureWidget::lowerposition=0.9;
	$ScalableFeatureWidget::otherposition=0.9;
	$ScalableFeatureWidget::bodythickness=0.075;
	$ScalableFeatureWidget::totalthickness=0.15;    
    } else {
	@ScalableFeatureWidget::positions=(0.2, 0.4, 0.6, 0.2, 0.4, 0.6);
	$ScalableFeatureWidget::lowerposition=0.9;
	$ScalableFeatureWidget::otherposition=0.9;
	$ScalableFeatureWidget::bodythickness=0.2;
	$ScalableFeatureWidget::totalthickness=0.4;    
    }

}

sub hide_frames {
    $ScalableFeatureWidget::frames_visible=0;
    if (!$ScalableFeatureWidget::strands_collapsed) {
	@ScalableFeatureWidget::positions=(0.2, 0.2, 0.2, 0.5, 0.5, 0.5);
	$ScalableFeatureWidget::lowerposition=0.9;
	$ScalableFeatureWidget::otherposition=0.9;
	$ScalableFeatureWidget::bodythickness=0.2;
	$ScalableFeatureWidget::totalthickness=0.4;    
    } else {
	@ScalableFeatureWidget::positions=(0.5, 0.5, 0.5, 0.5, 0.5, 0.5);
	$ScalableFeatureWidget::lowerposition=0.9;
	$ScalableFeatureWidget::otherposition=0.9;
	$ScalableFeatureWidget::bodythickness=0.2;
	$ScalableFeatureWidget::totalthickness=0.4;    
    }
}

sub collapse_strands {
    $ScalableFeatureWidget::strands_collapsed=1;
    if ($ScalableFeatureWidget::frames_visible) {
	@ScalableFeatureWidget::positions=(0.2, 0.4, 0.6, 0.2, 0.4, 0.6);
	$ScalableFeatureWidget::lowerposition=0.9;
	$ScalableFeatureWidget::otherposition=0.9;
	$ScalableFeatureWidget::bodythickness=0.1;
	$ScalableFeatureWidget::totalthickness=0.2;    
    } else {
	@ScalableFeatureWidget::positions=(0.5, 0.5, 0.5, 0.5, 0.5, 0.5);
	$ScalableFeatureWidget::lowerposition=0.9;
	$ScalableFeatureWidget::otherposition=0.9;
	$ScalableFeatureWidget::bodythickness=0.4;
	$ScalableFeatureWidget::totalthickness=0.8;    
    }

}

sub expand_strands {
    $ScalableFeatureWidget::strands_collapsed=0;
    if ($ScalableFeatureWidget::frames_visible) {
	@ScalableFeatureWidget::positions=(0.15, 0.25, 0.35, 0.45, 0.55, 0.65);
	$ScalableFeatureWidget::lowerposition=0.9;
	$ScalableFeatureWidget::otherposition=0.9;
	$ScalableFeatureWidget::bodythickness=0.075;
	$ScalableFeatureWidget::totalthickness=0.15;    
    } else {
	@ScalableFeatureWidget::positions=(0.2, 0.2, 0.2, 0.6, 0.6, 0.6);
	$ScalableFeatureWidget::lowerposition=0.9;
	$ScalableFeatureWidget::otherposition=0.9;
	$ScalableFeatureWidget::bodythickness=0.2;
	$ScalableFeatureWidget::totalthickness=0.4;    
    }
}


sub are_strands_collapsed {

    return $ScalableFeatureWidget::strands_collapsed;

}

sub are_frames_visible {
    return $ScalableFeatureWidget::frames_visible;
}

sub _new {
    my $class = shift;
    my $feature=shift;
    my $self = _new FeatureWidget('scalable',$feature);
    
    bless $self,$class;

    ($self->{start},$self->{end})=($feature->start,$feature->end);

    $self->{orientation}=1;
    if ($feature->strand == -1) {
	$self->{orientation}=-1;
    }


    return $self;
}

sub _determine_position {
    my $self=shift;
    my $start=shift;
    my $end=shift;
    my $strand=shift;


    if ($self->{feature}->primary_tag() eq 'CDS' ||
	$self->{feature}->primary_tag() eq 'gene') {
	if ($strand == 1) {
	    my $frame=($start-1)%3;
	    $self->{position}=$ScalableFeatureWidget::positions[$frame];
	} else {
	    my $frame=$end%3;
	    $self->{position}=$ScalableFeatureWidget::positions[$frame+3];
	}
    } else {
	$self->{position}=$ScalableFeatureWidget::otherposition;
    }

}

sub _draw_feature_name {
    my $self=shift;
    my $strip=shift;
    my $paintdevice = shift;
    my $draw_position_start=shift;
    my $draw_position_end=shift;

    my ($x_scale,$y_scale)=$strip->scale;
    my ($x_start,$y_start)=$strip->offset;

    my $name=undef;

    if ($self->{feature}->primary_tag eq 'gene' || 
	$self->{feature}->has_tag('gene')) {
	my (@dummy)=$self->{feature}->each_tag_value('gene');
	$name=shift @dummy;
    }

    if (!defined $name && $self->{feature}->primary_tag eq 'CDS' &&
	$self->{feature}->has_tag('product')) {
	my (@dummy)=$self->{feature}->each_tag_value('product');
	$name=shift @dummy;
	$name=undef
	    if ($name =~/\w+\s+\w+/);
    }

    if (defined($name) && 
	($draw_position_end-$draw_position_start)>
	$ScalableFeatureWidget::display_threshold) {
	my $text_x=$x_start+
	    $x_scale*($draw_position_end+$draw_position_start)/2;
	my $text_y=$y_start+($self->{position}-$ScalableFeatureWidget::totalthickness/2.0)*$y_scale;
	my $align_y='bottom';
	$paintdevice->add_text($text_x,$text_y,$name,
			       'halign'=>'middle','valign'=>$align_y);
    }
}


sub _draw {
    my $self=shift;
    my $strip=shift;
    my $paintdevice = shift;

    my ($startbase,$endbase)=$strip->get_bounds();
    my ($x_scale,$y_scale)=$strip->scale;
    my ($x_start,$y_start)=$strip->offset;

    my $draw_position_start=($self->{start}-$startbase)/($endbase-$startbase);
    $draw_position_start=0 if ($draw_position_start <0);
    $draw_position_start=1 if ($draw_position_start >1);

    my $draw_position_end=($self->{end}-$startbase)/($endbase-$startbase);
    $draw_position_end=0 if ($draw_position_end <0);
    $draw_position_end=1 if ($draw_position_end >1);

    $paintdevice->add_rectangle($x_start+$x_scale*$draw_position_start,
				$y_start+($self->{position}-$ScalableFeatureWidget::bodythickness/2.0)*$y_scale,
				$x_scale*
				($draw_position_end-$draw_position_start),
				$ScalableFeatureWidget::bodythickness*$y_scale);

    $self->_draw_feature_name($strip,$paintdevice,
			     $draw_position_start,$draw_position_end);

}

BEGIN {
    collapse_strands;
    hide_frames;
}

package ArrowFeatureWidget;

use strict;

@ArrowFeatureWidget::ISA=qw( ScalableFeatureWidget );

sub _new {
    my $class=shift;
    my $feature=shift;
    my $self=_new ScalableFeatureWidget $feature;
    $self->{color_direct}=shift;
    $self->{color_indirect}=shift;
    $self->{filled}=shift;
    bless $self,$class;
    return $self;
}

sub draw {
    my $self=shift;
    my $strip=shift;
    my $paintdevice = shift;

    my $deltay_body=$ScalableFeatureWidget::bodythickness/2.0;
    my $deltay_head=$ScalableFeatureWidget::totalthickness/2.0;


    
    my ($startbase,$endbase)=$strip->get_bounds();
    my ($x_scale,$y_scale)=$strip->scale;
    my ($x_start,$y_start)=$strip->offset;

    my $draw_position_start=($self->{start}-$startbase)/($endbase-$startbase);
    my $draw_position_end=($self->{end}-$startbase)/($endbase-$startbase);


    my $default_arrow_length=0.01;
    if ($draw_position_end-$draw_position_start < $default_arrow_length) {
	$default_arrow_length=$draw_position_end-$draw_position_start;
    }
    my $arrow_length=$default_arrow_length;
    my (@x,@y);
    my $color=$self->{color_direct};
    $color=$self->{color_indirect}
        if ($self->{feature}->strand == -1);


    $self->_determine_position($self->{start},$self->{end},$self->{feature}->strand);

    my $xmin=$x_start+$draw_position_start*$x_scale;
    $xmin=$x_start
	if ($xmin<$x_start);
    my $xmax=$x_start+$draw_position_end*$x_scale;
    $xmax=$x_start+$x_scale
	if ($xmax>$x_start+$x_scale);
    my $ymin=$y_start+($self->{position}-$ScalableFeatureWidget::totalthickness/2.0)*$y_scale;
    my $ymax=$y_start+($self->{position}+$ScalableFeatureWidget::totalthickness/2.0)*$y_scale;

    $paintdevice->add_reactive_zone($xmin,$ymin,$xmax,$ymax,$self->{feature})
	if ($paintdevice->type() eq 'reactive');

    if ($self->{feature}->strand != -1) {
	if ($draw_position_start<0) {
	    $draw_position_start=0;
	} else {
	    $paintdevice->add_line($x_start+$x_scale*$draw_position_start,
				   $y_start+($self->{position}-$deltay_head)*$y_scale,
				   $x_start+$x_scale*$draw_position_start,
				   $y_start+($self->{position}+$deltay_head)*$y_scale,
				   'color'=>$color);
	}
	push @x,$x_start+$x_scale*$draw_position_start;
	push @y,$y_start+($self->{position}+$deltay_body)*$y_scale;
	push @x,$x_start+$x_scale*$draw_position_start;
	push @y,$y_start+($self->{position}-$deltay_body)*$y_scale;
	if ($draw_position_end<=1) {
	    $arrow_length=$default_arrow_length;
	    if ($draw_position_end-$arrow_length<0) {
		$arrow_length=$draw_position_end;
	    }
	    push @x,$x_start+$x_scale*($draw_position_end-$arrow_length);
	    push @y,$y_start+($self->{position}-$deltay_body)*$y_scale;
	    push @x,$x_start+$x_scale*($draw_position_end-$arrow_length);
	    push @y,$y_start+($self->{position}-$deltay_head)*$y_scale;
	    push @x,$x_start+$x_scale*$draw_position_end;
	    push @y,$y_start+($self->{position})*$y_scale;
	    push @x,$x_start+$x_scale*($draw_position_end-$arrow_length);
	    push @y,$y_start+($self->{position}+$deltay_head)*$y_scale;
	    push @x,$x_start+$x_scale*($draw_position_end-$arrow_length);
	    push @y,$y_start+($self->{position}+$deltay_body)*$y_scale;
	}
	else {
	    $draw_position_end=1;
	    push @x,$x_start+$x_scale*$draw_position_end;
	    push @y,$y_start+($self->{position}-$deltay_body)*$y_scale;
	    push @x,$x_start+$x_scale*$draw_position_end;
	    push @y,$y_start+($self->{position}+$deltay_body)*$y_scale;
	}
    } else {
	if ($draw_position_end>1) {
	    $draw_position_end=1;
	} else {
	    $paintdevice->add_line($x_start+$x_scale*$draw_position_end,
				   $y_start+($self->{position}-$deltay_head)*$y_scale,
				   $x_start+$x_scale*$draw_position_end,
				   $y_start+($self->{position}+$deltay_head)*$y_scale,
				   'color'=>$color);
	}
	push @x,$x_start+$x_scale*$draw_position_end;
	push @y,$y_start+($self->{position}-$deltay_body)*$y_scale;
	push @x,$x_start+$x_scale*$draw_position_end;
	push @y,$y_start+($self->{position}+$deltay_body)*$y_scale;
	if ($draw_position_start>=0) {
	    $arrow_length=$default_arrow_length;
	    if ($draw_position_start+$arrow_length>1) {
		$arrow_length=1-$draw_position_start;
	    }
	    push @x,$x_start+$x_scale*($draw_position_start+$arrow_length);
	    push @y,$y_start+($self->{position}+$deltay_body)*$y_scale;
	    push @x,$x_start+$x_scale*($draw_position_start+$arrow_length);
	    push @y,$y_start+($self->{position}+$deltay_head)*$y_scale;
	    push @x,$x_start+$x_scale*$draw_position_start;
	    push @y,$y_start+($self->{position})*$y_scale;
	    push @x,$x_start+$x_scale*($draw_position_start+$arrow_length);
	    push @y,$y_start+($self->{position}-$deltay_head)*$y_scale;
	    push @x,$x_start+$x_scale*($draw_position_start+$arrow_length);
	    push @y,$y_start+($self->{position}-$deltay_body)*$y_scale;
	}
	else {
	    $draw_position_start=0;
	    push @x,$x_start+$x_scale*$draw_position_start;
	    push @y,$y_start+($self->{position}+$deltay_body)*$y_scale;
	    push @x,$x_start+$x_scale*$draw_position_start;
	    push @y,$y_start+($self->{position}-$deltay_body)*$y_scale;
	}
    }
    
    $self->_draw_feature_name($strip,$paintdevice,
			     $draw_position_start,$draw_position_end);

    $paintdevice->add_polygon(\@x,\@y,'filled'=>$self->{filled},'color'=>$color);
}

package CDSWidget;

use strict;

@CDSWidget::ISA=qw( ArrowFeatureWidget );

sub new {
    my $class=shift;
    my $feature = shift;
    my $filled=0;
    my $has_function=$feature->has_tag('function');
    if ($has_function) {
	my ($function,@dummy)=$feature->each_tag_value('function');
	$function=~s/"//g;   # "  
        $function=~tr/a-z/A-Z/; 
	$filled=1 
	    if ($function !~ /UNKNOWN/); 
    }
    $filled=1 
	if $feature->has_tag('product');
    my $self = _new ArrowFeatureWidget($feature,'cyan','magenta',$filled);

    bless $self,$class;

    return $self;
}

sub draw {
    my $self=shift;
    my $strip=shift;
    my $paintdevice = shift;


    my $deltay_body=$ScalableFeatureWidget::bodythickness/2.0;
    my $deltay_head=$ScalableFeatureWidget::totalthickness/2.0;


    
    my ($startbase,$endbase)=$strip->get_bounds();
    my ($x_scale,$y_scale)=$strip->scale;
    my ($x_start,$y_start)=$strip->offset;

    my $default_arrow_length=0.01;
    my $arrow_length=$default_arrow_length;
    my (@x,@y);

    $self->_determine_position($self->{start},$self->{end},$self->{feature}->strand);

    my $feature=$self->{feature};
    my $strand=$feature->strand();
    my $location=$feature->location();
    my $color=$self->{color_direct};
    $color=$self->{color_indirect}
        if ($self->{feature}->strand == -1);
    if ($location->isa("Bio::Location::SplitLocationI")) {
	my @sublocations=sort { $a->start <=> $b->start } $location->sub_Location();
	for (my $i=0;$i<=$#sublocations;$i++) {

	    my $arrow_head=0;
	    my $prevexonend=undef;
	    my $prevexonypos=undef;
	    if ($i>0) {
		$prevexonend=$sublocations[$i-1]->end;
		$self->_determine_position($sublocations[$i-1]->start,
				    $sublocations[$i-1]->end,$strand);
		$prevexonypos=$self->{position};
	    }

	    my $nextexonstart=undef;
	    my $nextexonend=undef;
	    my $nextexonypos=undef;	    
	    if ($i<$#sublocations) {
		$nextexonstart=$sublocations[$i+1]->start;
		$nextexonend=$sublocations[$i+1]->end;
		$self->_determine_position($nextexonstart,$nextexonend,$strand);
		$nextexonypos=$self->{position};
	    }

	    my $curexonstart=$sublocations[$i]->start;
	    my $curexonend=$sublocations[$i]->end;
	    $self->_determine_position($curexonstart,$curexonend,$strand);
	    my $curexonypos=$self->{position};


	    if ($i>0 && (($prevexonend<$startbase && $curexonstart>$endbase) ||
		($curexonend<$startbase && $nextexonstart>$endbase))) {
		$paintdevice->add_line($x_start,
				       $y_start+$self->{position}*$y_scale,
				       $x_start+$x_scale,
				       $y_start+$self->{position}*$y_scale,
				       'color'=>'black');
	    } 
	    my $sublocstart=$sublocations[$i]->start;
	    my $sublocend=$sublocations[$i]->end;
	    my $draw_position_start=($sublocstart-$startbase)/($endbase-$startbase);
	    my $draw_position_end=($sublocend-$startbase)/($endbase-$startbase);
	    if (($draw_position_start>=0 && $draw_position_start<=1) ||
		($draw_position_end>=0 && $draw_position_end<=1) ||
		($draw_position_start<=0 && $draw_position_end>=1)) {
		if ($i==0 && $draw_position_start>=0) {
		    if ($feature->strand()==1) {
			$paintdevice->add_line($x_start+$draw_position_start*$x_scale,
					       $y_start+($self->{position}-$ScalableFeatureWidget::bodythickness)*$y_scale,
					       $x_start+$draw_position_start*$x_scale,
					       $y_start+($self->{position}+$ScalableFeatureWidget::bodythickness)*$y_scale,
					       'color'=>$color);
		    }
		    if ($feature->strand()==-1) {
			my $arrow_end=$draw_position_end;
			$arrow_end=1
			    if ($arrow_end>1);
			push @x,$x_start+$x_scale*$arrow_end;
			push @y,$y_start+($self->{position}-$deltay_body)*$y_scale;
			push @x,$x_start+$x_scale*$arrow_end;
			push @y,$y_start+($self->{position}+$deltay_body)*$y_scale;
			$arrow_length=$default_arrow_length;
			if ($draw_position_start+$arrow_length>1) {
			    $arrow_length=1-$draw_position_start;
			}
			push @x,$x_start+$x_scale*($draw_position_start+$arrow_length);
			push @y,$y_start+($self->{position}+$deltay_body)*$y_scale;
			push @x,$x_start+$x_scale*($draw_position_start+$arrow_length);
			push @y,$y_start+($self->{position}+$deltay_head)*$y_scale;
			push @x,$x_start+$x_scale*$draw_position_start;
			push @y,$y_start+($self->{position})*$y_scale;
			push @x,$x_start+$x_scale*($draw_position_start+$arrow_length);
			push @y,$y_start+($self->{position}-$deltay_head)*$y_scale;
			push @x,$x_start+$x_scale*($draw_position_start+$arrow_length);
			push @y,$y_start+($self->{position}-$deltay_body)*$y_scale;
			$paintdevice->add_polygon(\@x,\@y,
						  'filled'=>$self->{filled},
						  'color'=>$color);
			$arrow_head=1;
		    }
		}
		if ($i==$#sublocations && $draw_position_end<=1) {
		    if ($feature->strand()==-1) {
			$paintdevice->add_line($x_start+$draw_position_end*$x_scale,
					       $y_start+($self->{position}-$ScalableFeatureWidget::bodythickness)*$y_scale,
					       $x_start+$draw_position_end*$x_scale,
					       $y_start+($self->{position}+$ScalableFeatureWidget::bodythickness)*$y_scale,
					       'color'=>$color);
		    }
		    if ($feature->strand()==1) {
			my $arrow_start=$draw_position_start;
			$arrow_start=0
			    if ($arrow_start<0);
			push @x,$x_start+$x_scale*$arrow_start;
			push @y,$y_start+($self->{position}+$deltay_body)*$y_scale;
			push @x,$x_start+$x_scale*$arrow_start;
			push @y,$y_start+($self->{position}-$deltay_body)*$y_scale;
			$arrow_length=$default_arrow_length;
			if ($draw_position_end-$arrow_length<0) {
			    $arrow_length=$draw_position_end;
			}
			push @x,$x_start+$x_scale*($draw_position_end-$arrow_length);
			push @y,$y_start+($self->{position}-$deltay_body)*$y_scale;
			push @x,$x_start+$x_scale*($draw_position_end-$arrow_length);
			push @y,$y_start+($self->{position}-$deltay_head)*$y_scale;
			push @x,$x_start+$x_scale*$draw_position_end;
			push @y,$y_start+($self->{position})*$y_scale;
			push @x,$x_start+$x_scale*($draw_position_end-$arrow_length);
			push @y,$y_start+($self->{position}+$deltay_head)*$y_scale;
			push @x,$x_start+$x_scale*($draw_position_end-$arrow_length);
			push @y,$y_start+($self->{position}+$deltay_body)*$y_scale;
			$paintdevice->add_polygon(\@x,\@y,
						  'filled'=>$self->{filled},
						  'color'=>$color);
			$arrow_head=1;
		    }
		}
		$draw_position_start=0
		    if ($draw_position_start<0);
		$draw_position_end=1
		    if ($draw_position_end>1);
		if ($i>0 && $draw_position_start>0) {
		    my $prevsublocend=$sublocations[$i-1]->end();
		    my $prevsublocdrawposx=($prevsublocend-$startbase)/($endbase-$startbase);
		    my $prevsublocdrawposy=$prevexonypos;
		    if ($prevsublocdrawposx<=0) {
			$paintdevice->add_line($x_start,
					       $y_start+$prevsublocdrawposy*$y_scale,
					       $x_start+$x_scale*$draw_position_start,
					       $y_start+$self->{position}*$y_scale,
					       'color'=>'black');
		    } else {
			if ($self->{position} == $prevexonypos) {
			    my $middle=$x_start+($draw_position_start+$prevsublocdrawposx)/2.0*$x_scale;
			    $paintdevice->add_line($x_start+$prevsublocdrawposx*$x_scale,
						   $y_start+$self->{position}*$y_scale,
						   $middle,
						   $y_start+($self->{position}-$self->{orientation}*$ScalableFeatureWidget::bodythickness/2.0)*$y_scale,
						   'color'=>'black');
			    $paintdevice->add_line($middle,
						   $y_start+($self->{position}-$self->{orientation}*$ScalableFeatureWidget::bodythickness/2.0)*$y_scale,
						   $x_start+$x_scale*$draw_position_start,
						   $y_start+$self->{position}*$y_scale,
						   'color'=>'black');
			}
			else {
			    $paintdevice->add_line($x_start+$prevsublocdrawposx*$x_scale,
						   $y_start+$prevsublocdrawposy*$y_scale,
						   $x_start+$draw_position_start*$x_scale,
						   $y_start+$self->{position}*$y_scale);

			}
		    }
		}
		if ($i<$#sublocations && $draw_position_end<1) {
		    my $nextsublocstart=$sublocations[$i+1]->start;
		    my $nextsublocdrawposx=($nextsublocstart-$startbase)/($endbase-$startbase);
		    my $nextsublocdrawposy=$nextexonypos;

		    if ($nextsublocdrawposx>=1) {
			$paintdevice->add_line($x_start+$draw_position_end*$x_scale,
					       $y_start+$self->{position}*$y_scale,
					       $x_start+$x_scale,
					       $y_start+$nextsublocdrawposy*$y_scale,
					       'color'=>'black');
		    }
		}
		if ($arrow_head==0) {
		    $paintdevice->add_rectangle($x_start+$x_scale*$draw_position_start,
						$y_start+($self->{position}-$ScalableFeatureWidget::bodythickness/2.0)*$y_scale,
						$x_scale*($draw_position_end-$draw_position_start),
						$ScalableFeatureWidget::bodythickness*$y_scale,'filled'=>$self->{filled},'color'=>$color);
		}
	    }
	}
	my $locationstart=$feature->start;
	my $locationend=$feature->end;
	my $draw_position_start=($locationstart-$startbase)/($endbase-$startbase);
	my $draw_position_end=($locationend-$startbase)/($endbase-$startbase);
	if (($draw_position_start>=0 && $draw_position_start<=1) ||
	    ($draw_position_end>=0 && $draw_position_end<=1) ||
	    ($draw_position_start<=0 && $draw_position_end>=1)) {
	    $draw_position_start=0
		if ($draw_position_start<0);
	    $draw_position_end=1
		if ($draw_position_end>1);
	    $self->_draw_feature_name($strip,$paintdevice,$draw_position_start,$draw_position_end);
	    my $xmin=$x_start+$draw_position_start*$x_scale;
	    $xmin=$x_start
		if ($xmin<$x_start);
	    my $xmax=$x_start+$draw_position_end*$x_scale;
	    $xmax=$x_start+$x_scale
		if ($xmax>$x_start+$x_scale);
	    my $ymin=$y_start+($self->{position}-$ScalableFeatureWidget::totalthickness/2.0)*$y_scale;
	    my $ymax=$y_start+($self->{position}+$ScalableFeatureWidget::totalthickness/2.0)*$y_scale;
	    $paintdevice->add_reactive_zone($xmin,$ymin,$xmax,$ymax,$self->{feature})
		if ($paintdevice->type() eq 'reactive');
	}

    } else {
	$self->ArrowFeatureWidget::draw($strip,$paintdevice);
    }
}

package misc_RNAWidget;

use strict;

@misc_RNAWidget::ISA=qw( ArrowFeatureWidget );

sub new {
    my $class=shift;
    my $feature = shift;
    my $self = _new ArrowFeatureWidget($feature,'green','green',1);

    bless $self,$class;
    return $self;
}

package SpearFeatureWidget;

use strict;

@SpearFeatureWidget::ISA=qw( ScalableFeatureWidget );


sub _new {
    my $class=shift;
    my $feature=shift;
    my $self=_new ScalableFeatureWidget $feature;
    $self->{color}=shift;
    $self->{filled}=shift;
    bless $self,$class;
    return $self;
}

sub draw {
    my $self=shift;
    my $strip=shift;
    my $paintdevice = shift;

    my $deltay_body=$ScalableFeatureWidget::bodythickness/2.0;
    my $deltay_head=$ScalableFeatureWidget::totalthickness/2.0;

    my ($startbase,$endbase)=$strip->get_bounds();
    my ($x_scale,$y_scale)=$strip->scale;
    my ($x_start,$y_start)=$strip->offset;

    my $draw_position_start=($self->{start}-$startbase)/($endbase-$startbase);
    my $draw_position_end=($self->{end}-$startbase)/($endbase-$startbase);


    my $default_arrow_length=0.01;
    if ($draw_position_end-$draw_position_start < $default_arrow_length) {
	$default_arrow_length=$draw_position_end-$draw_position_start;
    }
    my $arrow_length=$default_arrow_length;

    $self->_determine_position($self->{start},$self->{end},$self->{feature}->strand);

    my $xmin=$x_start+$draw_position_start*$x_scale;
    $xmin=$x_start
	if ($xmin<$x_start);
    my $xmax=$x_start+$draw_position_end*$x_scale;
    $xmax=$x_start+$x_scale
	if ($xmax>$x_start+$x_scale);
    my $ymin=$y_start+($self->{position}-$ScalableFeatureWidget::totalthickness/2.0)*$y_scale;
    my $ymax=$y_start+($self->{position}+$ScalableFeatureWidget::totalthickness/2.0)*$y_scale;

    $paintdevice->add_reactive_zone($xmin,$ymin,$xmax,$ymax,$self->{feature})
	if ($paintdevice->type() eq 'reactive');

    my (@x,@y);
    if ($self->{feature}->strand != -1) {
	if ($draw_position_start<0) {
	    $draw_position_start=0;
	} else {
	    $paintdevice->add_line($x_start+$x_scale*$draw_position_start,
				   $y_start+($self->{position}-$deltay_head)*$y_scale,
				   $x_start+$x_scale*$draw_position_start,
				   $y_start+($self->{position}+$deltay_head)*$y_scale,
				   'color'=>$self->{color});
	}
	push @x,$x_start+$x_scale*$draw_position_start;
	push @y,$y_start+($self->{position}-$deltay_body)*$y_scale;
	push @x,$x_start+$x_scale*$draw_position_start;
	push @y,$y_start+($self->{position}+$deltay_body)*$y_scale;
	if ($draw_position_end<=1) {
	    $arrow_length=$default_arrow_length;
	    if ($draw_position_end-$arrow_length<0) {
		$arrow_length=$draw_position_end;
	    }
	    push @x,$x_start+$x_scale*($draw_position_end-$arrow_length);
	    push @y,$y_start+($self->{position}+$deltay_body)*$y_scale;
	    push @x,$x_start+$x_scale*$draw_position_end;
	    push @y,$y_start+($self->{position})*$y_scale;
	    push @x,$x_start+$x_scale*($draw_position_end-$arrow_length);
	    push @y,$y_start+($self->{position}-$deltay_body)*$y_scale;
	}
	else {
	    $draw_position_end=1;
	    push @x,$x_start+$x_scale*$draw_position_end;
	    push @y,$y_start+($self->{position}+$deltay_body)*$y_scale;
	    push @x,$x_start+$x_scale*$draw_position_end;
	    push @y,$y_start+($self->{position}-$deltay_body)*$y_scale;
	}
    } else {
	if ($draw_position_end>1) {
	    $draw_position_end=1;
	} else {
	    $paintdevice->add_line($x_start+$x_scale*$draw_position_end,
				   $y_start+($self->{position}-$deltay_head)*$y_scale,
				   $x_start+$x_scale*$draw_position_end,
				   $y_start+($self->{position}+$deltay_head)*$y_scale,
				   'color'=>$self->{color});
	}
	push @x,$x_start+$x_scale*$draw_position_end;
	push @y,$y_start+($self->{position}-$deltay_body)*$y_scale;
	push @x,$x_start+$x_scale*$draw_position_end;
	push @y,$y_start+($self->{position}+$deltay_body)*$y_scale;
	if ($draw_position_start>=0) {
	    $arrow_length=$default_arrow_length;
	    if ($draw_position_start+$arrow_length>1) {
		$arrow_length=1-$draw_position_start;
	    }
	    push @x,$x_start+$x_scale*($draw_position_start+$arrow_length);
	    push @y,$y_start+($self->{position}+$deltay_body)*$y_scale;
	    push @x,$x_start+$x_scale*$draw_position_start;
	    push @y,$y_start+($self->{position})*$y_scale;
	    push @x,$x_start+$x_scale*($draw_position_start+$arrow_length);
	    push @y,$y_start+($self->{position}-$deltay_body)*$y_scale;
	}
	else {
	    $draw_position_start=0;
	    push @x,$x_start+$x_scale*$draw_position_start;
	    push @y,$y_start+($self->{position}+$deltay_body)*$y_scale;
	    push @x,$x_start+$x_scale*$draw_position_start;
	    push @y,$y_start+($self->{position}-$deltay_body)*$y_scale;
	}
    }
    
    $self->_draw_feature_name($strip,$paintdevice,
			     $draw_position_start,$draw_position_end);

    $paintdevice->add_polygon(\@x,\@y,'filled'=>$self->{filled},'color'=>$self->{color});
}


package tRNAWidget;

use strict;

@tRNAWidget::ISA=qw( SpearFeatureWidget );

sub new {
    my $class=shift;
    my $feature = shift;
    my $self = _new SpearFeatureWidget($feature,'blue',1);

    bless $self,$class;
    return $self;
}

package rRNAWidget;

use strict;

@rRNAWidget::ISA=qw( SpearFeatureWidget );

sub new {
    my $class=shift;
    my $feature = shift;
    my $self = _new SpearFeatureWidget($feature,'red',1);

    bless $self,$class;
    return $self;
}

package InvisibleWidget;

use strict;

@InvisibleWidget::ISA=qw( ScalableFeatureWidget );

sub new {
    my $class=shift;
    my $feature = shift;
    my $self = _new ScalableFeatureWidget($feature);

    bless $self,$class;
    return $self;
}

sub draw {
    # An InvisibleWidget doesn't draw itself !
}

package DefaultWidget;

use strict;

@DefaultWidget::ISA=qw( ScalableFeatureWidget );

sub new {
    my $class=shift;
    my $feature = shift;
    my $self = _new ScalableFeatureWidget($feature,'black',0);
    $self->{position}=$ScalableFeatureWidget::lowerposition;
    bless $self,$class;
    return $self;
}

sub draw {
    my $self=shift;
    my $strip=shift;
    my $paintdevice =shift;

    $self->ScalableFeatureWidget::_draw($strip,$paintdevice);
    
    my $deltay_body=$ScalableFeatureWidget::bodythickness/2.0;
    my $deltay_head=$ScalableFeatureWidget::totalthickness/2.0;

    my ($startbase,$endbase)=$strip->get_bounds();
    my ($x_scale,$y_scale)=$strip->scale;
    my ($x_start,$y_start)=$strip->offset;

    my $draw_position_start=($self->{start}-$startbase)/($endbase-$startbase);
    $draw_position_start=0 if ($draw_position_start <0);
    $draw_position_start=1 if ($draw_position_start >1);

    my $draw_position_end=($self->{end}-$startbase)/($endbase-$startbase);
    $draw_position_end=0 if ($draw_position_end <0);
    $draw_position_end=1 if ($draw_position_end >1);

    my $xmin=$x_start+$draw_position_start*$x_scale;
    $xmin=$x_start
	if ($xmin<$x_start);
    my $xmax=$x_start+$draw_position_end*$x_scale;
    $xmax=$x_start+$x_scale
	if ($xmax>$x_start+$x_scale);
    my $ymin=$y_start+($self->{position}-$ScalableFeatureWidget::totalthickness/2.0)*$y_scale;
    my $ymax=$y_start+($self->{position}+$ScalableFeatureWidget::totalthickness/2.0)*$y_scale;

    $paintdevice->add_reactive_zone($xmin,$ymin,$xmax,$ymax,$self->{feature})
	if ($paintdevice->type() eq 'reactive');

    my $name=$self->{feature}->primary_tag;
    if (defined($name) && 
	($draw_position_end-$draw_position_start)>
	$ScalableFeatureWidget::display_threshold) {
	my $text_x=$x_start+
	    $x_scale*($draw_position_end+$draw_position_start)/2;
	my $align_y='top';
	my $text_y=$y_start+
	    ($self->{position}+$ScalableFeatureWidget::bodythickness/2.0)
		*$y_scale;
	$paintdevice->add_text($text_x,$text_y,$name,
			       'halign'=>'middle','valign'=>$align_y);
    }
}

package FeatureWidgetFactory;

use strict;

BEGIN {

    %FeatureWidgetFactory::MaskedFeatures = ();
    %FeatureWidgetFactory::FeatureTypes = ();

    %FeatureWidgetFactory::Factory = 
	(
	 CDS => sub { return new CDSWidget shift},
	 misc_RNA => sub { return  new misc_RNAWidget shift},
	 promoter => sub { return new PromoterWidget shift},
	 rRNA => sub { return new rRNAWidget shift},
	 terminator => sub { return new TerminatorWidget shift},
	 tRNA => sub { return new tRNAWidget shift},
	 source => sub {return new DefaultWidget shift},
	 misc_feature => sub {return new DefaultWidget shift},
	 default => sub { return new DefaultWidget shift}
	 );
}

sub get_widget_instance {
    my $feature = shift;
    my $feature_name = $feature->primary_tag;
    
    if (!defined $FeatureWidgetFactory::FeatureNames{$feature_name}) {
	$FeatureWidgetFactory::FeatureNames{$feature_name}=1;
	$FeatureWidgetFactory::MaskedFeatures{$feature_name}=0;
    }


    if ($FeatureWidgetFactory::MaskedFeatures{$feature_name} == 1) {
	return new InvisibleWidget $feature;
    } else {
    }


    
    return &{$FeatureWidgetFactory::Factory{$feature_name}}($feature)
	if (defined $FeatureWidgetFactory::Factory{$feature_name});

    return &{$FeatureWidgetFactory::Factory{default}}($feature);


}


sub mask_feature {
    my $name=shift;
    if (!defined $FeatureWidgetFactory::FeatureNames{$name}) {
	$FeatureWidgetFactory::FeatureNames{$name}=1;
    }
    $FeatureWidgetFactory::MaskedFeatures{$name}=1;
}

sub unmask_feature {
    my $name=shift;
    if (!defined $FeatureWidgetFactory::FeatureNames{$name}) {
	$FeatureWidgetFactory::FeatureNames{$name}=1;
    }
    $FeatureWidgetFactory::MaskedFeatures{$name}=0;
}


sub is_masked {
    my $name=shift;
    
    my $ret=0;

    $ret=1
	if ($FeatureWidgetFactory::MaskedFeatures{$name}==1);

    return $ret;
}

sub get_feature_names {
    my @namelist=();

    foreach my $name (sort keys %FeatureWidgetFactory::FeatureNames) {
	push @namelist,$name;
    }
    return @namelist;
}

1
__END__

=head1 NAME

FeatureWidget - A perl module to graphically render gene annotation features.

=head1 SYNOPSIS

   use Bio::SeqFeature::Generic;
   use FeatureWidget;


   # Create some dummy features.
   my $cdsfeat=new Bio::SeqFeature::Generic(-start => 250,-end => 750,
					    -strand => 1,
					    -primary => 'CDS',
					    -tag => {
						product => 'some protein',
						gene => 'example gene'
						}
					    );

   my $promfeat=new Bio::SeqFeature::Generic(-start => 250,-end =>250,
					     -strand => 1,
					     -primary => 'promoter'
					     );

   my $termfeat=new Bio::SeqFeature::Generic(-start => 750,-end => 750,
					     -strand => 1,
					     -primary => 'terminator'
					     );

   # Get widget instances for the features
   my $cdswidget=FeatureWidgetFactory::get_widget_instance($cdsfeat);
   my $promwidget=FeatureWidgetFactory::get_widget_instance($promfeat);
   my $termwidget=FeatureWidgetFactory::get_widget_instance($termfeat);


   # Create the strips to display the feature widgets :
   # - one AxisStrip for positional features (top half of window),
   # - ons FeatureStrip for CDS widget (bottom half of window).
   my $posstrip=new AxisStrip(1,1000,0.0,0.0,1.0,0.49);
   my $scalestrip=new FeatureStrip(1,1000,0.0,0.5,1.0,0.5);

   # Add features to appropriate strips.
   $posstrip->add_feature_widget($promwidget);
   $posstrip->add_feature_widget($termwidget);
   $scalestrip->add_feature_widget($cdswidget);

   # Create device to draw widgets (Gtk window in this case).
   my $device=new GtkPaintDevice(800,200);

   # Draw strips on device. 
   $posstrip->draw($device);
   $scalestrip->draw($device);

   # Render device.
   $device->render;

=head1 DESCRIPTION

This module contains several classes each representing a drawable feature on a physical map. Both abstract classes (allowing easy extension to new feature types) and classes for the most common feature types are provided.

A I<FeatureWidgetFactory> class included in the package eases the instantiation of new feature widgets from features as defined in the I<Bio::SeqFeatureI> module.

=head1 CLASS HIERARCHY

The class hierarchy is as follows :

 FeatureWidget
   |------- PostionalFeatureWidget
   |            |------------------ PromoterWidget
   |            |------------------ TerminatorWidget
   |
   |------- ScalableFeatureWidget
   |            |------------------ DefaultWidget
   |            |------------------ ArrowFeatureWidget
   |            |                       |----------------CDSWidget
   |            |                       |----------------misc_RNAWidget
   |            |
   |            |------------------ SpearFeatureWidget
   |                                    |----------------tRNAWdiget
   |                                    |----------------rRNAWidget
   |
   |------- SourceWidget

=head2 FeatureWidget

Base class of all feature widget classes. It is an abstract class containing some data common to all widgets  and provides the following methods:

=over

=item _new (type,feature)

Protected method called in subclass constructors to initialize common data members. 

Parameters:
    I<type>: string giving the type of the feature widget, either "positional" or "scalable",
    I<feature>: reference to an object of type I<Bio::SeqFeatureI> containing the feature caracteristics.

Returns: a new instance of a FeatureWidget.

=item type

Method returning the type of the feature widget.

Returns: the type of the feature widget, either "positional" or "scalable".

=back

=head2 PositionalFeatureWidget

Base class of all features located at a defined position on the physical map (as opposed to features covering a given portion of the map). This is an abstract class providing the following methods:


=over

=item _new (feature,color)

Protected method called in subclass constructors to initialize common data members.

Parameters:
    I<feature>: reference to an object of type I<Bio::SeqFeatureI> containing the feature caracteristics.
    I<color> : the color to be used to draw the widget.

Returns: a new instance of a PositionalFeatureWidget.

=item _draw (strip,paintdevice)

Protected method drawing the common elements of all PositionalFeatureWidgets: a small vertical segment is drawn either above or below the horizontal axis depending on the strand the feature belongs to. The horizontal position of the segment is given by the start or the end base of the feature.

Parameters:
    I<strip>: the I<PhysicalMapStrip> this PositionalFeatureWidget belongs to,
    I<paintdevice>: the I<PaintDevice> on which this PositionalFeatureWidget is to be drawn.

=back

=head2 PromoterWidget

Class implementing the drawing of a promoter symbol at a given location and providing the following methods:

=over

=item new (feature)

Constuctor instantiating a new PromoterWidget.

Parameter:
    I<feature>: reference to an object of type I<Bio::SeqFeatureI> containing the feature caracteristics.


Returns: a new instance of a PromoterWidget.

=item draw (strip,paintdevice)

Method drawing a promoter symbol (black vertical segment associated to a small horizontal arrow) on a physical map.

Parameters:
    I<strip>: the I<PhysicalMapStrip> this PromoterWidget belongs to,
    I<paintdevice>: the I<PaintDevice> on which this PromoterWidget is to be drawn.

=back

=head2 TerminatorWidget

Class implementing the drawing of a terminator symbol at a given location and providing the following methods:

=over

=item new (feature)

Constuctor instantiating a new TerminatorWidget.

Parameter:
    I<feature>: reference to an object of type I<Bio::SeqFeatureI> containing the feature caracteristics.


Returns: a new instance of a TerminatorWidget.

=item draw (strip,paintdevice)

Method drawing a terminator symbol (red vertical segment ended by a small circle) on a physical map.

Parameters:
    I<strip>: the I<PhysicalMapStrip> this TerminatorWidget belongs to,
    I<paintdevice>: the I<PaintDevice> on which this TerminatorWidget is to be drawn.

=back

=head2 ScalableFeatureWidget

Base class for all features extending over a given portion of the physical map. This class provides the following methods:

=over

=item _new (feature)

Protected method used by subclass constructors to initialize common data members.

Parameter:
    I<feature>: reference to an object of type I<Bio::SeqFeatureI> containing the feature caracteristics.


Returns: a new instance of a ScalableFeatureWidget.

=item _draw_feature_name (strip,paintdevice,pos_start,pos_end)

Protected method used to draw the name of the gene of this feature, if it exists, above or below the horizontal center position  of feature widget.

Parameters:
    I<strip>: the I<PhysicalMapStrip> this ScalableFeatureWidget belongs to,
    I<paintdevice>: the I<PaintDevice> on which this ScalableFeatureWidget is to be drawn,
    I<pos_start>: the horizontal starting position of the feature relative to the PhysicalMapStrip's extents, in  [0..1],
    I<pos_end>: the horizontal ending position of the feature relative to the PhysicalMapStrip's extents, in  [0..1].

=item _draw (strip,paintdevice)

Protected method drawing common elements of all ScalableFeatureWidgets. This default method draws an unfilled black rectangle representing the feature on the physical map. The feature name is also drawn.

Parameters:
    I<strip>: the I<PhysicalMapStrip> this ScalableFeatureWidget belongs to,
    I<paintdevice>: the I<PaintDevice> on which this ScalableFeatureWidget is to be drawn.

=back

=head2 ArrowFeatureWidget

This subclass of ScalableFeatureWidget is designed for the drawing of 'arrow-like' scalable feature widgets : rectangular feature widgets having one arrow-like extremity. It provides the following methods :

=over

=item _new (feature,color1,color2,isfilled)

Protected method used by subclass constructors to initialize common data members.

Parameters:
    I<feature>: reference to an object of type I<Bio::SeqFeatureI> containing the feature caracteristics,
    I<color1>: color for ArrowFeatureWidgets lying on the +1 or 0 strands,
    I<color2>: color for ArrowFeatureWidgets lying on the -1 strand.
    I<isfilled>: boolean value (0,1) indicating the widget will or not be filled.

Returns: a new instance of an ArrowFeatureWidget.

=item draw (strip,paintdevice)

Method drawing the ArrowFeatureWidget

Parameters:
    I<strip>: the I<PhysicalMapStrip> this ArrowFeatureWidget belongs to,
    I<paintdevice>: the I<PaintDevice> on which this ArrowFeatureWidget is to be drawn.

=back

=head2 CDSWidget

Class used to draw CDS features on physical maps. It provides the following methods:

=over

=item new (feature)

Constructor for the CDS feature widget (cyan- or magenta-colored arrow widget, filled if gene has know function or product).

Parameters:
    I<feature>: reference to an object of type I<Bio::SeqFeatureI> containing the feature caracteristics.

Returns: a new instance of a CDSWidget.

=back

=head2 misc_RNAWidget

Class used to draw misc_RNA features on physical maps. It provides the following methods:

=over

=item new (feature)

Constructor for the misc_RNA feature widget (filled, green-colored arrow widget).

Parameters:
    I<feature>: reference to an object of type I<Bio::SeqFeatureI> containing the feature caracteristics.

Returns: a new instance of a misc_RNAWidget.

=back

=head2 SpearFeatureWidget

This subclass of ScalableFeatureWidget is designed to draw rectangular widgets having one triangular extremity. It provides the following methods:

=over

=item _new (feature,color,isfilled)

Protected method used by subclass constructors to initialize common data members.

Parameters:
    I<feature>: reference to an object of type I<Bio::SeqFeatureI> containing the feature caracteristics,
    I<color>: widget color,
    I<isfilled>: boolean value (0,1) indicating the widget will or not be filled.

Returns: a new instance of a SpearFeatureWidget.

=item draw (strip,paintdevice)

Method drawing the SpearFeatureWidget

Parameters:
    I<strip>: the I<PhysicalMapStrip> this SpearFeatureWidget belongs to,
    I<paintdevice>: the I<PaintDevice> on which this SpearFeatureWidget is to be drawn.

=back

=head2 tRNAWidget

Class used to draw tRNA features on physical maps. It provides the following methods :

=over

=item new (feature)

Constructor for the tRNA feature widget (filled, blue, spear-like widget).

Parameters:
    I<feature>: reference to an object of type I<Bio::SeqFeatureI> containing the feature caracteristics.

Returns: a new instance of a tRNAWidget.

=item draw(strip,paintdevice)

Method drawing the tRNAWidget.

Parameters:
    I<strip>: the I<PhysicalMapStrip> this tRNAWidget belongs to,
    I<paintdevice>: the I<PaintDevice> on which this tRNAWidget is to be drawn.


=back

=head2 rRNAWidget

Class used to draw rRNA features on physical maps. It provides the following methods :

=over

=item new (feature)

Constructor for the rRNA feature widget (filled, blue, spear-like widget).

Parameters:
    I<feature>: reference to an object of type I<Bio::SeqFeatureI> containing the feature caracteristics.

Returns: a new instance of an rRNAWidget.

=item draw(strip,paintdevice)

Method drawing the rRNAWidget.

Parameters:
    I<strip>: the I<PhysicalMapStrip> this rRNAWidget belongs to,
    I<paintdevice>: the I<PaintDevice> on which this rRNAWidget is to be drawn.


=back

=head2 SourceWidget

Class used to draw (rather to avoid the drawing of) a source feature. Source features usually span the whole physical map. This do-nothing class is provided to avoid cluttering the display with source feature widgets. It provides the following methods:

=over

=item new (feature)

Constructor for source feature widgets.

Parameter:
    I<feature>: reference to an object of type I<Bio::SeqFeatureI> containing the feature caracteristics.


Returns: a new instance of a SourceWidget.

=item draw ([...])

Empty method.

Parameters :
    I<...>: all parameters to this method are ignored.

=back

=head2 DefaultWidget

Class providing a default representation for all features not defined in specific feature widget classes. It provides the following methods:

=over

=item new(feature)

Constructor for default feature widgets (empty black rectangles).

Parameters:
    I<feature>: reference to an object of type I<Bio::SeqFeatureI> containing the feature caracteristics.

Returns: a new instance of a DefaultWidget.

=item draw (strip,paintdevice)

Method drawing a default feature widget on a physical map.

Parameters:
    I<strip>: the I<PhysicalMapStrip> this rRNAWidget belongs to,
    I<paintdevice>: the I<PaintDevice> on which this rRNAWidget is to be drawn.

=back

=head2 FeatureWidgetFactory

Class allowing easy instanciation of feature widgets based on their primary tag. It provides the following method:

=over

=item get_widget_instance (feature)

Method instantiating a new feature widget based on the primary tag of a feature.

Parameter:
    I<feature>: the feature for which a new widget has to be created.

Returns: a new instance of the specific feature widget, if it exists, or a new instance of a default feature widget. 

=back

=head1 CREATING NEW FEATURE WIDGETS

=head2 The easy way

The easiest way to define new feature widgets is to create subclasses of existing classes. If one of the existing leaf-classes (PromoterWidget, CDSWidget, tRNAWidget...) has the right appearance but you want your widget to have another color, simply cut an paste its code, replace the class name by your new widget name and insert your own color(s) in its constructor. Don't forget to add the widget to the widget factory (see below).

For example, to create a widget for the 'misc_feature' feature, based on the misc_RNA feature widget, copy the code of the misc_RNAWidget class and make the changes indicated in the comments :

    package misc_featureWidget;  # changed from misc_RNAWidget

    use strict;

    @misc_RNAWidget::ISA=qw( ArrowFeatureWidget );

    sub new {
        my $class=shift;
        my $feature = shift;
        my $self = _new ArrowFeatureWidget($feature,'yellow','yellow',1);
                                      #changed from 'green','green'
        bless $self,$class;
        return $self;
    }


=head2 The hard way

If you want to create a new widget not based on one of the existing ones some more work has to be done. First of all determine if your widget represents a positional feature (one covering only one or a small number of bases) or a scalable one (exceeding a few dozens of bases). Choose your widget's parent class accordingly, and implement a constructor and a draw method. 

In the draw method, when adding graphics primitives to the paintdevice, all coordinates are expressed in this paintdevice's coordinate system. Use the strip's parameters (scale, offset and bounds) to position and rescale these primitives correctly (see the PhysicalMapStrip documentation for more details, or examine the draw method of existing widgets.).

=head2 Adding the widget to the factory

In order for the new widget to be automagically instantiated when needed, add an entry to the %FeatureWidget::Factory hash table. The key is the string representing the feature your widget stands for, and the value is a sub call returnin an instance of this widget.

=head1 SEE ALSO

The I<FeatureWidget> module is part of a physical map drawing package and closely cooperates with the I<PhysicalMapStrip> and I<PaintDevice> modules of this package.

=head1 CONTACT

Any comments, questions, bug reports and patches are to be sent to : mh@jouy.inra.fr

=head1 VERSION

	$Id$	


=cut
