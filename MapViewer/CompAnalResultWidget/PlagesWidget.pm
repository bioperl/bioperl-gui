package CompAnalResultWidget::PlagesWidget;

use strict;

@CompAnalResultWidget::PlagesWidget::ISA=qw(CompAnalResultWidget);

BEGIN {
    $CompAnalResultWidgetFactory::Factory{PLAGES}=sub { return new CompAnalResultWidget::PlagesWidget @_ };
}

sub new  {
    my $class=shift;
    my $companalresult=shift;
    my $self=new CompAnalResultWidget('interlace');;

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

    my @colortab=('red','green','blue','cyan','magenta','yellow');
    my $numcolors=6;

    foreach my $plage (@{$self->{companalresult}->{plages}}) {
	if (($plage->{start}>=$startbase && $plage->{start}<=$endbase) ||
	    ($plage->{end}>=$startbase && $plage->{end}<=$endbase) ||
	    ($plage->{start}<=$startbase && $plage->{end}>=$endbase)) {
	    my $color=$colortab[$plage->{class} % $numcolors];
	    my $draw_position_start=($plage->{start}-$startbase)/
		($endbase-$startbase);
	    $draw_position_start=0
		if ($draw_position_start<0);
	    my $draw_position_end=($plage->{end}-$startbase)/
		($endbase-$startbase);
	    $draw_position_end=1
		if ($draw_position_end>1);
	    $paintdevice->add_rectangle($x_start+$x_scale*$draw_position_start,
					$y_start+0.25*$y_scale,
					($draw_position_end-$draw_position_start)*$x_scale,
					0.5*$y_scale,'filled'=>0,'color'=>$color);
	    my $text_x=$x_start+
		$x_scale*($draw_position_end+$draw_position_start)/2;
	    my $text_y=$y_start+$y_scale*0.5;
	    $paintdevice->add_text($text_x,$text_y,$plage->{class},
				   'halign'=>'middle','valign'=>'middle');
	}
    }
}

1
