package PaintDevice::ImageMapPaintDevice;

use strict;

use PaintDevice::ReactivePaintDevice;
use PaintDevice::PNGPaintDevice;

use GD;

@PaintDevice::ImageMapPaintDevice::ISA=qw(PaintDevice::PNGPaintDevice PaintDevice::ReactivePaintDevice);

sub new {
    my $class=shift;
    my $self= new PaintDevice::PNGPaintDevice(@_);

    $self->{urlprefix}=@_[$#{@_}];

    $self->{type}='reactive';

    bless $self,$class;

    return $self;
}

sub render {
    my $self = shift;

    $self->PaintDevice::PNGPaintDevice::render();

    print << "EOHTML";
<map name="physicalmap">
EOHTML
    foreach my $r_zone (@{$self->{r_zones}}) {
	my $xmin=int($r_zone->{xmin}*$self->{width});
	my $ymin=int($r_zone->{ymin}*$self->{height});
	my $xmax=int($r_zone->{xmax}*$self->{width});
	my $ymax=int($r_zone->{ymax}*$self->{height});
	my $feature=$r_zone->{userdata};
	my $tag=$feature->primary_tag();
	my $namestring='';
	if (lc $tag eq 'gene' || $feature->has_tag('gene')) {
	    my ($name,@dummy)=$feature->each_tag_value('gene');
	    $namestring="&name=$name";
	}
	my $start=$feature->start();
	my $end=$feature->end();
	
	print << "EOHTML";
	<area shape="rect" coords="$xmin,$ymin,$xmax,$ymax" href="$self->{urlprefix}tag=$tag$namestring&start=$start&end=$end">\n
EOHTML

    }
    print << "EOHTML";
</map>
EOHTML
}

1
