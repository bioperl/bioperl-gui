package PaintDevice::PSPaintDevice;

use strict;

@PaintDevice::PSPaintDevice::ISA=qw(PaintDevice);

$PaintDevice::PSPaintDevice::CM_PER_INCH = 2.54;
$PaintDevice::PSPaintDevice::POINTS_PER_INCH = 72;
$PaintDevice::PSPaintDevice::FONT_SIZE = 10;
$PaintDevice::PSPaintDevice::MARGIN_CM = 1;
$PaintDevice::PSPaintDevice::PAGE_HEIGHT_CM=28;

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
    my $pointwidth=($self->{width}-$PaintDevice::PSPaintDevice::MARGIN_CM*2)/
	$PaintDevice::PSPaintDevice::CM_PER_INCH*$PaintDevice::PSPaintDevice::POINTS_PER_INCH;
    my $pointheight=$self->{height}/$PaintDevice::PSPaintDevice::CM_PER_INCH*
	$PaintDevice::PSPaintDevice::POINTS_PER_INCH;
    my $side_offset=$PaintDevice::PSPaintDevice::MARGIN_CM/$PaintDevice::PSPaintDevice::CM_PER_INCH*
	$PaintDevice::PSPaintDevice::POINTS_PER_INCH;
    my $bottom_offset=($PaintDevice::PSPaintDevice::PAGE_HEIGHT_CM-$self->{height}-
		       $PaintDevice::PSPaintDevice::MARGIN_CM)/
			   $PaintDevice::PSPaintDevice::CM_PER_INCH*
			       $PaintDevice::PSPaintDevice::POINTS_PER_INCH;
    open(PSFILE,"> $self->{filename}") || 
	die "Unable to open file $self->{filename}";

    print PSFILE << "EOPSFILE";
%!PS-Adobe-3.0
%%Creator: PhysicalMapWidget
%%Pages : 1
$side_offset $bottom_offset translate
%---Color definitions----
EOPSFILE
    foreach my $color (keys (%{$self->{colortab}})) {
	my $red=$self->{colortab}->{$color}->{red};
	my $green=$self->{colortab}->{$color}->{green};
	my $blue=$self->{colortab}->{$color}->{blue};
	print PSFILE "/$color {$red $green $blue setrgbcolor} def\n";
    }

    print PSFILE << "EOPSFILE";
%----Drawing Macros----
/line {newpath moveto lineto closepath stroke} def
/empty_circle {0 360 arc stroke} def
/filled_circle {0 360 arc fill} def
/empty_box {newpath moveto dup 0 exch rlineto exch 0 rlineto neg 0 exch rlineto closepath stroke} def
/filled_box {newpath moveto dup 0 exch rlineto exch 0 rlineto neg 0 exch rlineto closepath fill} def
/left_text {/Courier findfont $PaintDevice::PSPaintDevice::FONT_SIZE scalefont setfont moveto show } def
/right_text {/Courier findfont $PaintDevice::PSPaintDevice::FONT_SIZE scalefont setfont moveto dup stringwidth pop neg 0 rmoveto show } def
/middle_text {/Courier findfont $PaintDevice::PSPaintDevice::FONT_SIZE scalefont setfont moveto dup stringwidth pop 2 div neg 0 rmoveto show } def
/empty_polygon {
    3 1 roll newpath moveto {lineto} repeat closepath stroke
} def
/filled_polygon {
    3 1 roll newpath moveto {lineto} repeat closepath fill
} def
/polyline {
    3 1 roll newpath moveto {lineto} repeat stroke
} def
%----Feature Drawings----
EOPSFILE
    
    for (my $depth=$#{$self->{primitives}};$depth>=0;$depth--) {
	for (my $shapeno=0;$shapeno<=$#{$self->{primitives}->[$depth]};$shapeno++) {
	    my $shape=$self->{primitives}->[$depth]->[$shapeno];
	    print PSFILE "$shape->{color}\n";
	    if ($shape->{type} eq 'text') {
		my $text_x=$shape->{x}*$pointwidth;
		my $text_y=(1.0-$shape->{y})*$pointheight;
		
		$text_y-=$PaintDevice::PSPaintDevice::FONT_SIZE/2
		    if ($shape->{v_align} eq 'middle');
		$text_y-=$PaintDevice::PSPaintDevice::FONT_SIZE
		    if ($shape->{v_align} eq 'top');
		print PSFILE "($shape->{text}) $text_x $text_y ";
		print PSFILE "left_text\n"
		    if ($shape->{h_align} eq 'left') ;
		print PSFILE "right_text\n"
		    if ($shape->{h_align} eq 'right');
		print PSFILE "middle_text\n"
		    if ($shape->{h_align} eq 'middle'); 
	    }
	    if ($shape->{type} eq 'line') {
		my $x1=$shape->{x1}*$pointwidth;
		my $y1=(1.0-$shape->{y1})*$pointheight;
		my $x2=$shape->{x2}*$pointwidth;
		my $y2=(1.0-$shape->{y2})*$pointheight;
		print PSFILE "$x1 $y1 $x2 $y2 line\n";
	    }
	    if ($shape->{type} eq 'circle') {
		my $x=$shape->{x}*$pointwidth;
		my $y=(1.0-$shape->{y})*$pointheight;
		my $r=$shape->{radius}*$pointheight;
		print PSFILE "$x $y $r empty_circle\n" if ($shape->{filled}==0);
		print PSFILE "$x $y $r filled_circle\n" if ($shape->{filled}==1);
	    }
	    if ($shape->{type} eq 'rectangle') {
		my $x=$shape->{x}*$pointwidth;
		my $y=(1.0-$shape->{y})*$pointheight;
		my $w=$shape->{width}*$pointwidth;
		my $h=-$shape->{height}*$pointheight;
		print PSFILE "$w $h $x $y empty_box\n" if ($shape->{filled}==0);
		print PSFILE "$w $h $x $y filled_box\n" if ($shape->{filled}==1);
	    }
	    if ($shape->{type} eq 'polygon') {
		for (my $i=$#{$shape->{x}};$i>=0;$i--) {
		    my $x=$shape->{x}->[$i]*$pointwidth;
		    my $y=(1.0-$shape->{y}->[$i])*$pointheight;
		    print PSFILE "$x $y ";
		}
		print PSFILE "$#{$shape->{x}} ";
		print PSFILE "empty_polygon\n" if ($shape->{filled}==0);
		print PSFILE "filled_polygon\n" if ($shape->{filled}==1);
	    }
	    if ($shape->{type} eq 'polyline') {
		for (my $i=$#{$shape->{x}};$i>=0;$i--) {
		    my $x=$shape->{x}->[$i]*$pointwidth;
		    my $y=(1.0-$shape->{y}->[$i])*$pointheight;
		    print PSFILE "$x $y ";
		}
		print PSFILE "$#{$shape->{x}} ";
		print PSFILE "polyline\n";
	    }
	}    
    }
    print PSFILE "showpage\n%%EOF\n";
    close(PSFILE);

}

sub text_height {
 my $self = shift;

 return $PaintDevice::PSPaintDevice::FONT_SIZE/$PaintDevice::PSPaintDevice::POINTS_PER_INCH*
     $PaintDevice::PSPaintDevice::CM_PER_INCH;
 
}

1
