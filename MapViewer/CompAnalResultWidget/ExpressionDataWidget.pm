package CompAnalResultWidget::ExpressionDataWidget;

use strict;

@CompAnalResultWidget::ExpressionDataWidget::ISA=qw(CompAnalResultWidget);

BEGIN {
    $CompAnalResultWidgetFactory::Factory{EXPRESSIONDATA}=sub { return new CompAnalResultWidget::ExpressionDataWidget @_ };
}


sub new  {
    my $class=shift;
    my $companalresult=shift;
    my $self=new CompAnalResultWidget('interlace');

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


    foreach my $gene (@{$self->{companalresult}->{genes}}) {
	if (($gene->{start}>=$startbase && $gene->{start}<=$endbase) ||
	    ($gene->{end}>=$startbase && $gene->{end}<=$endbase) ||
	    ($gene->{start}<=$startbase && $gene->{end}>=$endbase)) {
	    my $draw_position_start=($gene->{start}-$startbase)/
		($endbase-$startbase);
	    $draw_position_start=0
		if ($draw_position_start<0);
	    my $draw_position_end=($gene->{end}-$startbase)/
		($endbase-$startbase);
	    $draw_position_end=1
		if ($draw_position_end>1);

	    $paintdevice->add_rectangle($x_start+$x_scale*$draw_position_start,
					$y_start+0.70*$y_scale,
					($draw_position_end-$draw_position_start)*$x_scale,
					0.15*$y_scale,'filled'=>1,'color'=>'red')
		if ($gene->{wt_growth});
	    $paintdevice->add_rectangle($x_start+$x_scale*$draw_position_start,
					$y_start+0.45*$y_scale,
					($draw_position_end-$draw_position_start)*$x_scale,
					0.15*$y_scale,'filled'=>1,'color'=>'green')
		if ($gene->{mutant_growth});
	    $paintdevice->add_rectangle($x_start+$x_scale*$draw_position_start,
					$y_start+0.20*$y_scale,
					($draw_position_end-$draw_position_start)*$x_scale,
					0.15*$y_scale,'filled'=>1,'color'=>'blue')
		if ($gene->{betagal});
	    $paintdevice->add_text($x_start+$x_scale*($draw_position_end+$draw_position_start)/2,$y_start,$gene->{gene},'halign'=>'middle','valign'=>'bottom');
	}
    }
}

1
