package PhysicalMapStripSet;

use strict;

use PhysicalMapStrip;

$PhysicalMapStripSet::AXISINDEX=0;
$PhysicalMapStripSet::SEQUENCEINDEX=1;
$PhysicalMapStripSet::FEATUREINDEX=2;

sub new {
    my $class = shift;
    my $self = {};
    my $map=shift;
    my $startbase=shift;
    my $endbase=shift;

    $self->{startbase}=$startbase;
    $self->{endbase}=$endbase;
    $self->{strips}=[];

    $self->{strips}->[$PhysicalMapStripSet::AXISINDEX]=new AxisStrip($startbase,$endbase);
    $self->{strips}->[$PhysicalMapStripSet::SEQUENCEINDEX]=new SequenceStrip($map,$startbase,$endbase);
    $self->{strips}->[$PhysicalMapStripSet::FEATUREINDEX]=new FeatureStrip($map,$startbase,$endbase);

    $self->{scalablecompanalresultwidgets} = [];
    $self->{sequencecompanalresultwidgets} = [];
    $self->{interlacecompanalresultwidgets} = [];
    $self->{backgroundcolor}='yellow';



    bless $self,$class;
    return $self;
    
}

sub add_feature_widget {
    my $self=shift;
    my $widget=shift;
    my $axis_strip=$self->{strips}->[$PhysicalMapStripSet::AXISINDEX];
    my $scalable_strip=$self->{strips}->[$PhysicalMapStripSet::FEATUREINDEX];
    if (defined $widget && $widget->type eq 'positional') {
	$axis_strip->add_feature_widget($widget);
    }
    if (defined $widget && $widget->type eq 'scalable') {
	$scalable_strip->add_feature_widget($widget);
    }
}

sub add_companal_result_widget {
    my $self=shift;
    my $widget=shift;

    if ($widget->layout eq 'feature_overlay' || $widget->layout eq 'overlay'){
	push @{$self->{scalablecompanalresultwidgets}},{widget=>$widget,
							strip=>$self->{strips}->[$PhysicalMapStripSet::FEATUREINDEX]};
    }
    if ($widget->layout eq 'sequence_overlay' || $widget->layout eq 'overlay'){
	push @{$self->{sequencecompanalresultwidgets}},{widget=>$widget,
							strip=>$self->{strips}->[$PhysicalMapStripSet::SEQUENCEINDEX]};
    }
    if ($widget->layout eq 'interlace') {
	push @{$self->{strips}},new ScalableStrip($self->{startbase},
						 $self->{endbase});
	push @{$self->{interlacecompanalresultwidgets}},{widget=>$widget,
							 strip=>$self->{strips}->[$#{$self->{strips}}]};
    }

}

sub area {
    my $self=shift;
    my $left_x=shift;
    if (defined $left_x) {
	$self->{x_left}=$left_x;
	$self->{y_top}=shift;
	$self->{width}=shift;
	$self->{height}=shift;

	my $stripset_height_in_lines=$self->height_in_lines;
	my $cur_height=$self->{y_top};
	foreach my $strip (@{$self->{strips}}) {
	    if ($strip->name() ne 'SequenceStrip' || 
		($self->{endbase}-$self->{startbase} <
		 $PhysicalMapWidget::sequence_display_threshold)) {
		my $strip_height=$strip->height_in_lines/$stripset_height_in_lines*
		    $self->{height};
		$strip->offset($self->{x_left},$cur_height);
		$strip->scale($self->{width},$strip_height);
		$cur_height+=$strip_height;
	    }
	}
    } else {
	return ($self->{x_left},$self->{y_top},$self->{width},$self->{height});
    }
}

sub draw {
    my $self=shift;
    my $paintdevice=shift;
    $paintdevice->add_rectangle($self->{x_left},$self->{y_top},
				$self->{width},$self->{height},
				'filled'=>1,
				'color'=>$self->{backgroundcolor},
				'depth'=>999);
				
    foreach my $strip (@{$self->{strips}}) {
	$strip->draw($paintdevice)
	    if ($strip->name() ne 'SequenceStrip' || 
		($self->{endbase}-$self->{startbase} <
		 $PhysicalMapWidget::sequence_display_threshold));
    }
    foreach my $companalref (@{$self->{interlacecompanalresultwidgets}}) {
	$companalref->{widget}->draw($paintdevice,$companalref->{strip});
    }
    foreach my $companalref (@{$self->{scalablecompanalresultwidgets}}) {
	$companalref->{widget}->draw($paintdevice,$companalref->{strip});
    }
    if ($self->{endbase}-$self->{startbase} <
	$PhysicalMapWidget::sequence_display_threshold) {
	foreach my $companalref (@{$self->{sequencecompanalresultwidgets}}) {
	    $companalref->{widget}->draw($paintdevice,$companalref->{strip});
	}
    }

}

sub height_in_lines {
    my $self=shift;
    my $lines=0;
    foreach my $strip (@{$self->{strips}}) {
	$lines+=$strip->height_in_lines;
    }
    return $lines;
}

sub set_background_color{
    my $self=shift;
    my $color=shift;

    $self->{backgroundcolor}=$color;
}

1
