package PaintDevice::XFigPaintDevice;

use strict;

@PaintDevice::XFigPaintDevice::ISA=qw( PaintDevice );

$PaintDevice::XFigPaintDevice::CM_PER_INCH = 2.54;
$PaintDevice::XFigPaintDevice::POINTS_PER_INCH = 1200;
$PaintDevice::XFigPaintDevice::FONT_SIZE = 11;
$PaintDevice::XFigPaintDevice::FONT_HEIGHT_CM = 0.3;
$PaintDevice::XFigPaintDevice::MARGIN_CM = 1;
$PaintDevice::XFigPaintDevice::PAGE_HEIGHT_CM=28;

sub new {
    my $class = shift;
    my $self = _new PaintDevice ;

    $self->{filename} = shift;
    $self->{width} = shift;
    $self->{height} = shift;

    bless $self,$class;

    return $self;
}

sub render {
    my $self = shift;
    my $pointwidth=($self->{width}-$PaintDevice::XFigPaintDevice::MARGIN_CM*2)/
	$PaintDevice::XFigPaintDevice::CM_PER_INCH*$PaintDevice::XFigPaintDevice::POINTS_PER_INCH;
    my $pointheight=$self->{height}/$PaintDevice::XFigPaintDevice::CM_PER_INCH*
	$PaintDevice::XFigPaintDevice::POINTS_PER_INCH;
    my $side_offset=$PaintDevice::XFigPaintDevice::MARGIN_CM/$PaintDevice::XFigPaintDevice::CM_PER_INCH*
	$PaintDevice::XFigPaintDevice::POINTS_PER_INCH;
    my $bottom_offset=($PaintDevice::XFigPaintDevice::PAGE_HEIGHT_CM-$self->{height}-
		       $PaintDevice::XFigPaintDevice::MARGIN_CM)/
			   $PaintDevice::XFigPaintDevice::CM_PER_INCH*
			       $PaintDevice::XFigPaintDevice::POINTS_PER_INCH;

    open(XFIGFILE,"> $self->{filename}") || 
	die "Unable to open file $self->{filename}";

    print XFIGFILE << "EOXFIGFILE";
#FIG 3.2
Portrait
Center
Metric
A4
100.0
Single
-1
$PaintDevice::XFigPaintDevice::POINTS_PER_INCH 2
EOXFIGFILE

    my $colorcounter=32;
    my %colortab=();
    foreach my $color (keys (%{$self->{colortab}})) {
	my $red=int($self->{colortab}->{$color}->{red}*255);
	my $green=int($self->{colortab}->{$color}->{green}*255);
	my $blue=int($self->{colortab}->{$color}->{blue}*255);
	printf XFIGFILE "0 %d #%.2x%.2x%.2x\n",$colorcounter,$red,$green,$blue;
	$colortab{$color}=$colorcounter++;

    }



    for (my $depth=$#{$self->{primitives}};$depth>=0;$depth--) {
	for (my $shapeno=0;$shapeno<=$#{$self->{primitives}->[$depth]};$shapeno++) {
	    my $shape=$self->{primitives}->[$depth]->[$shapeno];
	    if ($shape->{type} eq 'text') {
		my $text_x=$shape->{x}*$pointwidth;
		my $text_y=$shape->{y}*$pointheight;
		
		$text_y+=$PaintDevice::XFigPaintDevice::FONT_HEIGHT_CM/
		    $PaintDevice::XFigPaintDevice::CM_PER_INCH*
			$PaintDevice::XFigPaintDevice::POINTS_PER_INCH/2
			    if ($shape->{v_align} eq 'middle');
		$text_y+=$PaintDevice::XFigPaintDevice::FONT_HEIGHT_CM/
		    $PaintDevice::XFigPaintDevice::CM_PER_INCH*
			$PaintDevice::XFigPaintDevice::POINTS_PER_INCH
			    if ($shape->{v_align} eq 'top');
		$text_x=int($text_x);
		$text_y=int($text_y);
		my $justified=0;
		$justified=1 if ($shape->{h_align} eq 'middle');
		$justified=2 if ($shape->{h_align} eq 'right');
		print XFIGFILE "4 $justified $colortab{$shape->{color}} $depth 0 5 $PaintDevice::XFigPaintDevice::FONT_SIZE 0.0 0 1.0 1.0 $text_x $text_y $shape->{text}\\001\n";
	    }
	    if ($shape->{type} eq 'line') {
		my $x1=int($shape->{x1}*$pointwidth);
		my $y1=int($shape->{y1}*$pointheight);
		my $x2=int($shape->{x2}*$pointwidth);
		my $y2=int($shape->{y2}*$pointheight);
		print XFIGFILE "2 1 0 1 $colortab{$shape->{color}} $colortab{$shape->{color}} $depth 0 -1 1.0 0 0 1 0 0 2\n$x1 $y1 $x2 $y2\n";
	    }
	    if ($shape->{type} eq 'circle') {
		my $fill=-1;
		$fill=20 if ($shape->{filled}==1);
		my $x=int($shape->{x}*$pointwidth);
		my $y=int($shape->{y}*$pointheight);
		my $r=int($shape->{radius}*$pointheight);
		my $leftx=int($shape->{x}*$pointwidth+
			      $shape->{radius}*$pointheight);
		print XFIGFILE "1 3 0 1  $colortab{$shape->{color}} $colortab{$shape->{color}} $depth 0  $fill 1.0 1 0.0 $x $y $r $r $x $y $leftx $y\n";
	    }
	    if ($shape->{type} eq 'rectangle') {
		my $fill=-1;
		$fill=20 if ($shape->{filled}==1);
		my $x1=int($shape->{x}*$pointwidth);
		my $y1=int($shape->{y}*$pointheight);
		my $x2=int(($shape->{x}+$shape->{width})*$pointwidth);
		my $y2=int(($shape->{y}+$shape->{height})*$pointheight);
		if ($x1==$x2 || $x2==$y2) {
		    print XFIGFILE "2 1 0 1 $colortab{$shape->{color}} $colortab{$shape->{color}} $depth 0 -1 1.0 0 0 1 0 0 2\n$x1 $y1 $x2 $y2\n";
		}
		else {
		    print XFIGFILE "2 2 0 1 $colortab{$shape->{color}} $colortab{$shape->{color}} $depth 0 $fill 1.0 0 0 1 0 0 5\n";
		    print XFIGFILE "$x1 $y1 $x1 $y2 $x2 $y2 $x2 $y1 $x1 $y1\n";
		}
	    }
	    if ($shape->{type} eq 'polygon') {
		my $fill=-1;
		$fill=20 if ($shape->{filled}==1);
		my $npoints=$#{$shape->{x}}+2;
		print XFIGFILE "2 3 0 1 $colortab{$shape->{color}} $colortab{$shape->{color}} $depth 0 $fill 1.0 0 0 1 0 0 $npoints\n";
		for (my $i=0;$i<=$#{$shape->{x}};$i++) {
		    my $x=int($shape->{x}->[$i]*$pointwidth);
		    my $y=int($shape->{y}->[$i]*$pointheight);
		    print XFIGFILE "$x $y\n";
		}
		my $last_x=int($shape->{x}->[0]*$pointwidth);
		my $last_y=int($shape->{y}->[0]*$pointheight);
		print XFIGFILE "$last_x $last_y\n";
	    }
	    if ($shape->{type} eq 'polyline') {
		my $npoints=$#{$shape->{x}}+1;
		if ($npoints == 2) {
		    my $x1=int($shape->{x}->[0]*$pointwidth);
		    my $y1=int($shape->{y}->[0]*$pointheight);
		    my $x2=int($shape->{x}->[1]*$pointwidth);
		    my $y2=int($shape->{y}->[1]*$pointheight);
		    print XFIGFILE "2 1 0 1 $colortab{$shape->{color}} $colortab{$shape->{color}} $depth 0 -1 1.0 0 0 1 0 0 2\n$x1 $y1 $x2 $y2\n";
		} else {
		    print XFIGFILE "2 1 0 1 $colortab{$shape->{color}} $colortab{$shape->{color}} $depth 0 -1 1.0 0 0 1 0 0 $npoints\n";
		    for (my $i=0;$i<=$#{$shape->{x}};$i++) {
			my $x=int($shape->{x}->[$i]*$pointwidth);
			my $y=int($shape->{y}->[$i]*$pointheight);
			print XFIGFILE "$x $y\n";
		    }
		}
	    }
	}    
    }
    close(XFIGFILE);

}

sub text_height {
 my $self = shift;

 return $PaintDevice::XFigPaintDevice::FONT_HEIGHT_CM;
 
}

1
