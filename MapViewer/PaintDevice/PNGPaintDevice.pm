package PaintDevice::PNGPaintDevice;

use strict;


use GD;

@PaintDevice::PNGPaintDevice::ISA=qw(PaintDevice);

sub new {
    my $class=shift;
    my $self= _new PaintDevice;

    $self->{filename}=shift;
    $self->{width}=shift;
    $self->{height}=shift;

    bless $self,$class;

    return $self;
}

sub render {
    my $self = shift;

    my $image=new GD::Image($self->{width},$self->{height});
    my $width=$self->{width};
    my $height=$self->{height};

    my %colortab=();
    foreach my $color (keys (%{$self->{colortab}})) {
	my $red=int($self->{colortab}->{$color}->{red}*255);
	my $green=int($self->{colortab}->{$color}->{green}*255);
	my $blue=int($self->{colortab}->{$color}->{blue}*255);
	$colortab{$color}=$image->colorAllocate($red,$green,$blue);
    }

    $image->filledRectangle(0,0,$width-1,$height-1,$colortab{'white'});

    my $font=GD::Font->Small;
    my $fontwidth=$font->width;
    my $fontheight=$font->height;

    for (my $depth=$#{$self->{primitives}};$depth>=0;$depth--) {
	for (my $shapeno=0;$shapeno<=$#{$self->{primitives}->[$depth]};$shapeno++) {
	    my $shape=$self->{primitives}->[$depth]->[$shapeno];
	    if ($shape->{type} eq 'text') {
		my $text_x=$shape->{x}*($width-1);
		my $stringwidth=$fontwidth*length($shape->{text});
		my $h_align=$shape->{h_align};
		if ($h_align eq 'right') {
		    $text_x-=$stringwidth;
		}
		if ($h_align eq 'middle') {
		    $text_x-=$stringwidth/2;
		}
		my $text_y=$shape->{y}*($height-1);
		my $v_align=$shape->{v_align};
		if ($v_align eq 'middle') {
		    $text_y-=$fontheight/2;
		}
		if ($v_align eq 'bottom') {
		    $text_y-=$fontheight;
		}
		$image->string($font,$text_x,$text_y,$shape->{text},
			       $colortab{$shape->{color}});
	    }
	    if ($shape->{type} eq 'line') {
		my $x1=int($shape->{x1}*$width);
		my $y1=int($shape->{y1}*$height);
		my $x2=int($shape->{x2}*$width);
		my $y2=int($shape->{y2}*$height);
		$image->line($x1,$y1,$x2,$y2,$colortab{$shape->{color}});
	    }
	    if ($shape->{type} eq 'circle') {
		my $x=int($shape->{x}*$width);
		my $y=int($shape->{y}*$height);
		my $r=int($shape->{radius}*$height*2);
		$image->arc($x,$y,$r,$r,0,360,$colortab{$shape->{color}});
		if ($shape->{filled}) {
		    $image->fill($x,$y,$colortab{$shape->{color}});
		}
	    }
	    if ($shape->{type} eq 'rectangle') {
		my $x1=int($shape->{x}*$width);
		my $y1=int($shape->{y}*$height);
		my $x2=int(($shape->{x}+$shape->{width})*$width);
		my $y2=int(($shape->{y}+$shape->{height})*$height);
		if ($shape->{filled}==1) {
		    $image->filledRectangle($x1,$y1,$x2,$y2,
					    $colortab{$shape->{color}});
		} else {
		    $image->rectangle($x1,$y1,$x2,$y2,
				      $colortab{$shape->{color}});
		}
	    }
	    if ($shape->{type} eq 'polygon') {
		my $poly=new GD::Polygon;
		for (my $i=0;$i<=$#{$shape->{x}};$i++) {
		    my $x=int($shape->{x}->[$i]*$width);
		    my $y=int($shape->{y}->[$i]*$height);
		    $poly->addPt($x,$y);
		}
		if ($shape->{filled}==1) {
		    $image->filledPolygon($poly,$colortab{$shape->{color}});
		} else {
		    $image->polygon($poly,$colortab{$shape->{color}});
		}
	    }
	    if ($shape->{type} eq 'polyline') {
		my ($x1,$y1,$x2,$y2);
		for (my $i=0;$i<=$#{$shape->{x}};$i++) {
		    $x2=int($shape->{x}->[$i]*$width);
		    $y2=int($shape->{y}->[$i]*$height);
		    $image->line($x1,$y1,$x2,$y2,$colortab{$shape->{color}})
			if ($i>0);
		    $x1=$x2;
		    $y1=$y2;
		}
	    }
	}    
    }

    open PNGFILE,"> $self->{filename}";
    binmode PNGFILE;
    print PNGFILE $image->png;
    close PNGFILE;
}

sub text_height {
    my $self=shift;
    return GD::Font->Small->height;
}

1
