package CompAnalResultWidget::OperonsWidget;

use strict;

@CompAnalResultWidget::OperonsWidget::ISA=qw(CompAnalResultWidget);


BEGIN {
    $CompAnalResultWidgetFactory::Factory{OPERONS}=sub { return new CompAnalResultWidget::OperonsWidget @_ };
}

sub new  {
    my $class=shift;
    my $companalresult=shift;
    my $self=new CompAnalResultWidget('feature_overlay');

    bless $self,$class;

    $self->{companalresult}=$companalresult;

    return $self;
}

sub draw {
    my $self = shift;
    my $paintdevice = shift;
    my $strip = shift;

    my ($startbase,$endbase)=$strip->get_bounds;
    my ($x_scale,$y_scale)=$strip->scale;
    my ($x_start,$y_start)=$strip->offset;

    my @colortab=('red','black','green');

    foreach my $operon (@{$self->{companalresult}->{operons}}) {
	if (($operon->{start}>=$startbase && $operon->{start}<=$endbase) ||
	    ($operon->{end}>=$startbase && $operon->{end}<=$endbase) ||
	    ($operon->{start}<=$startbase && $operon->{end}>=$endbase)) {
	    my $color=$colortab[$operon->{strand} + 1];
	    my $draw_position_start=($operon->{start}-$startbase)/
		($endbase-$startbase);
	    if ($draw_position_start>=0) {
		$paintdevice->add_line($x_start+$x_scale*$draw_position_start,
				       $y_start+0.10*$y_scale,
				       $x_start+$x_scale*$draw_position_start,
				       $y_start+0.9*$y_scale,'color'=>$color,
				       'depth'=>100);
	    } else {
		$draw_position_start=0;
	    }
	    my $draw_position_end=($operon->{end}-$startbase)/
		($endbase-$startbase);
	    if ($draw_position_end<=1) {
		$paintdevice->add_line($x_start+$draw_position_end*$x_scale,
				       $y_start+0.1*$y_scale,
				       $x_start+$draw_position_end*$x_scale,
				       $y_start+0.9*$y_scale,'color'=>$color);
	    } else {
		$draw_position_end=1;
	    }
	    $paintdevice->add_rectangle($x_start+$x_scale*$draw_position_start,
					$y_start+0.2*$y_scale,
					($draw_position_end-$draw_position_start)*$x_scale,
					0.6*$y_scale,'filled'=>0,'color'=>$color);
	}
    }
}

1
