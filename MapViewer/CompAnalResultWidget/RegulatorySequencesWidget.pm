package CompAnalResultWidget::RegulatorySequencesWidget;

use strict;

BEGIN {
    $CompAnalResultWidgetFactory::Factory{REGULATORYSEQUENCES}=sub { return new CompAnalResultWidget::RegulatorySequencesWidget @_ };
}

@CompAnalResultWidget::RegulatorySequencesWidget::ISA=qw(CompAnalResultWidget);

sub new  {
    my $class=shift;
    my $companalresult=shift;
    my $self=new CompAnalResultWidget('overlay');

    bless $self,$class;

    $self->{companalresult}=$companalresult;

    return $self;
}


sub draw {
    my $self = shift;
    my $paintdevice = shift;
    my $strip = shift;
    
    $self->_draw_scalable_strip($paintdevice,$strip)
	if ($strip->name eq 'ScalableStrip');
    $self->_draw_sequence_strip($paintdevice,$strip)
	if ($strip->name eq 'SequenceStrip');
}

sub _draw_scalable_strip {

    my $self = shift;
    my $paintdevice = shift;
    my $strip = shift;
    my ($startbase,$endbase)=$strip->get_bounds;
    my ($x_scale,$y_scale)=$strip->scale;
    my ($x_start,$y_start)=$strip->offset;

    foreach my $spot (@{$self->{companalresult}->{regseqs}}) {
	my $startpos=$spot->{pos};
	my $pattern=$spot->{pattern};
	my $strand=$spot->{strand};
	my $endpos=$startpos+$strand*(length($pattern)-1);
	($startpos,$endpos)=($endpos,$startpos)
	    if ($endpos<$startpos);
	if (($startpos>=$startbase && $startpos<=$endbase) ||
	    ($endpos>=$startbase && $endpos<=$endbase) ||
	    ($startpos<=$startbase && $endpos>=$endbase)) {
	    my $draw_position_start=($startpos-$startbase)/
		($endbase-$startbase);
	    my $draw_position_end=($endpos-$startbase)/
		($endbase-$startbase);
	    if ($strand==1) {
		$paintdevice->add_line($x_start+$x_scale*$draw_position_start,
				       $y_start+0.5*$y_scale,
				       $x_start+$x_scale*$draw_position_start,
				       $y_start+0.1*$y_scale,'color'=>'black');
		
		$paintdevice->add_line($x_start+$x_scale*$draw_position_start,
				       $y_start+0.1*$y_scale,
				       $x_start+$x_scale*$draw_position_end,
				       $y_start+0.1*$y_scale,'color'=>'black');
	    } else {
		$paintdevice->add_line($x_start+$x_scale*$draw_position_end,
				       $y_start+0.5*$y_scale,
				       $x_start+$x_scale*$draw_position_end,
				       $y_start+0.9*$y_scale,'color'=>'black');
		
		$paintdevice->add_line($x_start+$x_scale*$draw_position_end,
				       $y_start+0.9*$y_scale,
				       $x_start+$x_scale*$draw_position_start,
				       $y_start+0.9*$y_scale,'color'=>'black');
	    }
	}
    }
}



sub _draw_sequence_strip {

    my $self = shift;
    my $paintdevice = shift;
    my $strip = shift;
    my ($startbase,$endbase)=$strip->get_bounds;
    my ($x_scale,$y_scale)=$strip->scale;
    my ($x_start,$y_start)=$strip->offset;

    foreach my $spot (@{$self->{companalresult}->{regseqs}}) {
	my $startpos=$spot->{pos};
	my $pattern=$spot->{pattern};
	my $strand=$spot->{strand};
	my $endpos=$startpos+$strand*(length($pattern)-1);
	($startpos,$endpos)=($endpos,$startpos)
	    if ($endpos<$startpos);
	if (($startpos>=$startbase && $startpos<=$endbase) ||
	    ($endpos>=$startbase && $endpos<=$endbase) ||
	    ($startpos<=$startbase && $endpos>=$endbase)) {
	    my $draw_position_start=($startpos-$startbase-0.5)/
		($endbase-$startbase);
	    my $draw_position_end=($endpos-$startbase+0.5)/
		($endbase-$startbase);
	    my $draw_width=$draw_position_end-$draw_position_start;
	    if ($strand==1) {
		$paintdevice->add_rectangle($x_start+$x_scale*$draw_position_start,
				       $y_start+0.05*$y_scale,
				       $draw_width*$x_scale,
				       0.5*$y_scale,0,'red');
		} else {
		$paintdevice->add_rectangle($x_start+$x_scale*$draw_position_start,
				       $y_start+0.45*$y_scale,
				       $draw_width*$x_scale,
				       0.5*$y_scale,0,'red');
	    }
	}
    }
}

1
