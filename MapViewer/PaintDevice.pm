package PaintDevice;

use strict;

use Carp;

sub _init_colortab {
    my $self=shift;

    $self->color_alloc('black',0,0,0);
    $self->color_alloc('white',1.0,1.0,1.0);
    $self->color_alloc('red',1.0,0.0,0.0);
    $self->color_alloc('green',0.0,1.0,0.0);
    $self->color_alloc('blue',0.0,0.0,1.0);
    $self->color_alloc('yellow',1.0,1.0,0.0);
    $self->color_alloc('cyan',0.0,1.0,1.0);
    $self->color_alloc('magenta',1.0,0.0,1.0);
}

sub _new {
    my $class = shift;
    my $self = {};

    $self->{type}='generic';
    $self->{primitives}=[];
    $self->{colorcounter}=0;

    bless $self,$class;

    $self->{colortab}={};
    $self->_init_colortab();

    return $self;
}

sub width {
    my $self = shift;
    my $width = shift;

    return $self->{width} unless defined $width;
    $self->{width} = $width;
}

sub height {
    my $self = shift;
    my $height = shift;

    return $self->{height} unless defined $height;
    $self->{height}=$height;
}

sub clear {
    my $self = shift;

    $self->{primitives}=[];
}

=item

Method allocating new colors in this paintdevice's color table. All colors are defined in the RGB colorspace by three float values between 0.0 and 1.0 giving the intensity of each color component (red, green and blue).

If a color having the same name already exists in this paintdevice's colormap, its components are replaced with the new components given as arguments.

Usage: $colorid=$paintdevice->color_alloc($name,$r,$g,$b)

Arguments:

=over

=item $name: string representing a symbolic name form the color to be allocated.

=item= $r: float value in [0..1], intensity of the red color channel,

=item= $g: float value in [0..1], intensity of the green color channel,

=item= $b: float value in [0..1], intensity of the blue color channel,

=back

Returns: an identifier for the newly allocated color.

=cut

sub color_alloc {
    croak "usage: \$colorid=\$paintdevice->color_alloc(\$name,\$r,\$g,\$b)"
	if (@_ !=5);

    my $self=shift;
    my $name=shift;
    my ($red,$green,$blue)=@_;

    my $colorid=++$self->{colorcounter};
    if (defined $self->{colortab}->{$name}) {
	$colorid=$self->{colortab}->{$name}->{colorid};
	carp "PaintDevice::alloc_color: color $name was already defined.";
    }

    $self->{colortab}->{$name}->{colorid}=$colorid;
    $self->{colortab}->{$name}->{red}=$red;
    $self->{colortab}->{$name}->{green}=$green;
    $self->{colortab}->{$name}->{blue}=$blue;

    return $colorid;
}

sub color_defined {
    my $self=shift;
    my $name=shift;

    return 1
	if (defined $self->{colortab}->{$name});

    return 0;
}

sub add_line {
    my $self = shift;
    my $x1 = shift;
    my $y1 = shift;
    my $x2 = shift;
    my $y2 = shift;

    my %opts=('color'=>'black',
	      'depth'=>50);
    while (@_) {
	my $key=lc shift;
	if (defined $key) {
	    $opts{lc $key}=shift;
	}
    }
    $self->{primitives}->[$opts{'depth'}]=()
	if (!defined $self->{primitives}->[$opts{'depth'}]);
    push @{$self->{primitives}->[$opts{'depth'}]},{type=>'line',x1=>$x1,y1=>$y1,x2=>$x2,y2=>$y2,
				 color=>$opts{'color'}};
}

sub add_text {
    my $self = shift;
    my $x = shift;
    my $y = shift;
    my $text = shift;

    my %opts=('color'=>'black',
	      'depth'=>50,
	      'halign'=>'left',
	      'valign'=>'top');

    while (@_) {
	my $key=lc shift;
	if (defined $key) {
	    $opts{lc $key}=shift;
	}
    }
    $self->{primitives}->[$opts{'depth'}]=()
	if (!defined $self->{primitives}->[$opts{'depth'}]);
    push @{$self->{primitives}->[$opts{'depth'}]},{type=>'text',x=>$x,y=>$y,text=>$text,
				 color=>$opts{'color'},
				 h_align=>$opts{'halign'},
				 v_align=>$opts{'valign'}};
}

sub add_circle {
    my $self = shift;
    my $x = shift;
    my $y = shift;
    my $r = shift;

    my %opts=('color'=>'black',
	      'depth'=>50,
	      'filled'=>0);

    while (@_) {
	my $key=lc shift;
	if (defined $key) {
	    $opts{lc $key}=shift;
	}
    }

    $self->{primitives}->[$opts{'depth'}]=()
	if (!defined $self->{primitives}->[$opts{'depth'}]);
    push @{$self->{primitives}->[$opts{'depth'}]},{type=>'circle',x=>$x,y=>$y,radius=>$r,
			     filled=>$opts{'filled'},color=>$opts{'color'}};
}

sub add_rectangle {
    my $self = shift;
    my $x = shift;
    my $y = shift;
    my $width = shift;
    my $height = shift;

    my %opts=('color'=>'black',
	      'depth'=>50,
	      'filled'=>0);

    while (@_) {
	my $key=lc shift;
	if (defined $key) {
	    $opts{lc $key}=shift;
	}
    }

    $self->{primitives}->[$opts{'depth'}]=()
	if (!defined $self->{primitives}->[$opts{'depth'}]);
    push @{$self->{primitives}->[$opts{'depth'}]},{type=>'rectangle',x=>$x,y=>$y,
				 width=>$width,height=>$height,
				 filled=>$opts{'filled'},color=>$opts{'color'}};
}

sub add_polygon {
    my $self=shift;
    my $x=shift;
    my $y=shift;

    my %opts=('color'=>'black',
	      'depth'=>50,
	      'filled'=>0);

    while (@_) {
	my $key=lc shift;
	if (defined $key) {
	    $opts{lc $key}=shift;
	}
    }
    $self->{primitives}->[$opts{'depth'}]=()
	if (!defined $self->{primitives}->[$opts{'depth'}]);
    push @{$self->{primitives}->[$opts{'depth'}]},{type=>'polygon',x=>$x,y=>$y,
				filled=>$opts{'filled'},color=>$opts{'color'}};
}

sub add_polyline {
    my $self=shift;
    my $x=shift;
    my $y=shift;

    my %opts=('color'=>'black',
	      'depth'=>50);

    while (@_) {
	my $key=lc shift;
	if (defined $key) {
	    $opts{lc $key}=shift;
	}
    }
    $self->{primitives}->[$opts{'depth'}]=()
	if (!defined $self->{primitives}->[$opts{'depth'}]);
    push @{$self->{primitives}->[$opts{'depth'}]},{type=>'polyline',x=>$x,y=>$y,color=>$opts{'color'}};
				
}

sub render {
    die "PaintDevice::render called";
}

sub resize {
    my $self = shift;

    $self->{width} = shift;
    $self->{height} = shift;

}

sub text_height {
    die "PaintDevice::text_height called";
}


sub type {
    my $self=shift;

    return $self->{type};
}

sub copy_colormap {
    my $self=shift;
    my $paintdevice=shift;

    $paintdevice->{colortab}={};

    foreach my $color (keys %{$self->{colortab}}) {
	my $name=$self->{colortab}->{$color}->{name};
	my $colorid=$self->{colortab}->{$color}->{colorid};
    	my $red=$self->{colortab}->{$color}->{red};
    	my $green=$self->{colortab}->{$color}->{green};
    	my $blue=$self->{colortab}->{$color}->{blue};
	$paintdevice->{colortab}->{$color}->{name}=$name;
	$paintdevice->{colortab}->{$color}->{colorid}=$colorid;
	$paintdevice->{colortab}->{$color}->{red}=$red;
	$paintdevice->{colortab}->{$color}->{green}=$green;
	$paintdevice->{colortab}->{$color}->{blue}=$blue;
    }
    $paintdevice->{colorcounter}=$self->{colorcounter};
}

1
