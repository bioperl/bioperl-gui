package CompAnalResultWidget::RHOMWidget;

use strict;

@CompAnalResultWidget::RHOMWidget::ISA=qw(CompAnalResultWidget);

BEGIN {
    $CompAnalResultWidgetFactory::Factory{RHOM}=sub { return new CompAnalResultWidget::RHOMWidget @_ };
}

sub new {
    my $class = shift;
    my $companalresult=shift;
    my $self = new CompAnalResultWidget('feature_overlay');

    $self->{companalresult}=$companalresult;

    bless $self,$class;

    return $self;
}

sub draw {
    my $self = shift;
    my $paintdevice = shift;
    my $strip = shift;

    my ($startbase,$endbase)=$strip->get_bounds;
    my ($x_scale,$y_scale)=$strip->scale;
    my ($x_start,$y_start)=$strip->offset;

    my $companalresult=$self->{companalresult};
    foreach my $state (@{$companalresult->{states}}) {
	my $color=$state->{color};
	my $base=$state->{start};
	my $index=0;
	if ($base<$startbase) {
	    $index=$startbase-$base;
	    $base=$startbase;
	}
# else {
#	    if ($base>$startbase) {
#		$index=$base-$startbase;
#	    }
#	}
	my $last_y=-1;
	my @xcoords=();
	my @ycoords=();
	my $gap=0;
	my $prev_x=0;
	my $prev_y=0;
	while ($base<=$endbase && $index<=$#{$state->{data}}) {
	    my $x=$x_start+($base-$startbase)/($endbase-$startbase)*
		$x_scale;
	    my $current_y=$state->{data}->[$index];
	    my $y=$y_start+(1.0-$current_y)*$y_scale;
	    if (abs($last_y-$current_y)>=$state->{smoothing} || 
		$base==$endbase) {
		if ($gap) {
		    push @xcoords,$prev_x;
		    push @ycoords,$prev_y;
		    $gap=0;
		}
		push @xcoords,$x;
		push @ycoords,$y;
		$last_y=$current_y;		
	    } else {
		$gap=1;
		$prev_x=$x;
		$prev_y=$y;
	    }
	    $base++;
	    $index++;
	}
	$paintdevice->add_polyline(\@xcoords,\@ycoords,'color'=>$color)
	    if ($#xcoords>1);
	$paintdevice->add_line($xcoords[0],$ycoords[0],$xcoords[1],$ycoords[1],'color'=>$color)
	    if ($#xcoords==1);
    }
}

1
