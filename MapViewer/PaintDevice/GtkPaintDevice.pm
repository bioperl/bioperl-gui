package PaintDevice::GtkPaintDevice;

use strict;

use Gtk 0.7002;

use PaintDevice::ReactivePaintDevice;

@PaintDevice::GtkPaintDevice::ISA=qw(PaintDevice::ReactivePaintDevice);

$PaintDevice::GtkPaintDevice::GTK_INIT=0;
$PaintDevice::GtkPaintDevice::FONT_HEIGHT_POINTS=11;

sub new {
    my $class = shift;

    my $self = _new PaintDevice::ReactivePaintDevice;    

    $self->{width}=shift;
    $self->{height}=shift;
    $self->{window_width}=$self->{width};
    $self->{window_height}=$self->{height};

    $self->{parent_widget}=shift;


    $self->{r_widgets}=[];

    bless $self,$class;
    
    return $self;
}


sub _r_widget_entered {
    my $self=shift;
    my $userdata=shift;

    foreach my $listener (@{$self->{enter_listeners}}) {
	$listener->reactive_zone_entered($userdata);
    }
    
}


sub _r_widget_selected {
    my $self=shift;
    my $userdata=shift;

    foreach my $listener (@{$self->{select_listeners}}) {
	$listener->reactive_zone_selected($userdata);
    }
    
}


sub _r_widget_moved {
    my $self=shift;
    my $widget=shift;
    my $userdata=shift;
    my ($x,$y,$w,$h,$d)=$widget->window->get_geometry();
    my ($xp,$yp)=$widget->get_pointer();
    foreach my $listener (@{$self->{move_listeners}}) {
	$listener->reactive_zone_moved($xp/$w,$yp/$h,$userdata);
    }
    
}


sub render_core {
    my $self=shift;
    my $layout = $self->{layout};
    my $width=$self->{width};
    my $height=$self->{height};
    my $layoutwindow=$layout->window;

    my (undef, undef, undef, undef, $depth) = $layoutwindow->get_geometry;
    my $pixmap = new Gtk::Gdk::Pixmap($layoutwindow,$width,$height,$depth);

    my $gc=new Gtk::Gdk::GC $pixmap;
    my $font=load Gtk::Gdk::Font "fixed";
    my $font_height=$font->ascent+$font->descent;

    my %colortab = ();

    my $colormap=$layoutwindow->get_colormap;
    foreach my $color (keys (%{$self->{colortab}})) {
	my $red=int($self->{colortab}->{$color}->{red}*65535);
	my $green=int($self->{colortab}->{$color}->{green}*65535);
	my $blue=int($self->{colortab}->{$color}->{blue}*65535);
	my $gtkcolor=$colormap->color_alloc({red=>$red,
					    green=>$green,
					    blue=>$blue});
	$colortab{$color}=$gtkcolor;

    }
    $gc->set_foreground($colortab{'white'});
    $pixmap->draw_rectangle($gc,1,0,0,$width,$height);
    for (my $depth=$#{$self->{primitives}};$depth>=0;$depth--) {
	for (my $shapeno=0;$shapeno<=$#{$self->{primitives}->[$depth]};$shapeno++) {
	    my $shape=$self->{primitives}->[$depth]->[$shapeno];
	    $gc->set_foreground($colortab{$shape->{color}});
	    if ($shape->{type} eq 'line') {
		$pixmap->draw_line($gc,$shape->{x1}*($width-1),
				   $shape->{y1}*($height-1),
				   $shape->{x2}*($width-1),
				   $shape->{y2}*($height-1));
	    }
	    if ($shape->{type} eq 'text') {
		my $text_x=$shape->{x}*($width-1);
		my $h_align=$shape->{h_align};
		if ($h_align eq 'right') {
		    $text_x-=$font->string_width($shape->{text});
		}
		if ($h_align eq 'middle') {
		    $text_x-=$font->string_width($shape->{text})/2;
		}
		my $text_y=$shape->{y}*($height-1);
		my $v_align=$shape->{v_align};
		if ($v_align eq 'top') {
		    $text_y+=$font->ascent;
		}
		if ($v_align eq 'middle') {
		    $text_y+=$font_height/2;
		}
		if ($v_align eq 'bottom') {
		    $text_y-=$font->descent;
		}
		$pixmap->draw_string($font,$gc,$text_x,
				     $text_y,$shape->{text});
	    }
	    if ($shape->{type} eq 'rectangle') {
		$pixmap->draw_rectangle($gc,
					$shape->{filled},
					$shape->{x}*($width-1),
					$shape->{y}*($height-1),
					$shape->{width}*$width,
					$shape->{height}*$height);
	    }
	    if ($shape->{type} eq 'circle') {
		my $rect_x=$shape->{x}*($width-1)-$shape->{radius}*$height;
		my $rect_y=$shape->{y}*($height-1)-$shape->{radius}*$height;
		my $side_length=$shape->{radius}*$height*2;
		$pixmap->draw_arc($gc,
				  $shape->{filled},
				  $rect_x,$rect_y,
				  $side_length,$side_length,
				  0,360*64);
	    }
	    if ($shape->{type} eq 'polygon') {
		my (@draw_points);
		for (my $i=0;$i<=$#{$shape->{x}};$i++) {
		    push @draw_points,$shape->{x}->[$i]*($width-1);
		    push @draw_points,$shape->{y}->[$i]*($height-1);
		}
		$pixmap->draw_polygon($gc,
				      $shape->{filled},
				      @draw_points);
	    }
	    if ($shape->{type} eq 'polyline') {
		my (@draw_points);
		for (my $i=0;$i<=$#{$shape->{x}};$i++) {
		    push @draw_points,$shape->{x}->[$i]*($width-1);
		    push @draw_points,$shape->{y}->[$i]*($height-1);
		    if ($i>0 && $i<$#{$shape->{x}}) {
			push @draw_points,$shape->{x}->[$i]*($width-1);
			push @draw_points,$shape->{y}->[$i]*($height-1);
		    }
		}
		$pixmap->draw_segments($gc,
				       @draw_points);
	    }
	}
    }
    $gc->destroy;
    $self->{pixmap}=$pixmap;
}

sub _r_widget_expose {
    my $self=shift;
    my $widget=shift;

    my $window=$widget->window;
    my $srcwindow=$self->{area}->window;
    my $vadj=$self->{scrolledwindow}->get_vadjustment();
    my $hadj=$self->{scrolledwindow}->get_hadjustment();
    my $gc=new Gtk::Gdk::GC $window;

    my ($x,$y,$w,$h,$d)=$window->get_geometry();
    $window->draw_pixmap($gc,$self->{pixmap},$x+$hadj->value(),$y+$vadj->value(),0,0,$w,$h);
    $gc->destroy();
}

sub render_core_r_zones {
    my $self=shift;

    foreach my $widget (@{$self->{r_widgets}}) {
	$widget->destroy();
    }

    $self->{r_widgets}=[];
    $self->{layout}->freeze();
    foreach my $zone  (@{$self->{r_zones}}) {
	my $x=$zone->{xmin}*$self->{width};
	my $y=$zone->{ymin}*$self->{height};
	my $w=($zone->{xmax}-$zone->{xmin})*$self->{width};
	my $h=($zone->{ymax}-$zone->{ymin})*$self->{height};

	my $widget=new Gtk::DrawingArea;
	$widget->add_events("button_press_mask");
	$widget->add_events("button_release_mask");
	$widget->add_events("enter_notify_mask");
	$widget->add_events("pointer_motion_mask");
	$widget->signal_connect("enter_notify_event", sub {$self->_r_widget_entered($zone->{userdata})});
	$widget->signal_connect_after("motion_notify_event", sub {$self->_r_widget_moved($widget,$zone->{userdata})});
	$widget->signal_connect("button_release_event", sub {$self->_r_widget_selected($zone->{userdata})});
	$widget->signal_connect_after("expose_event", sub {$self->_r_widget_expose($widget)});
	$widget->set_usize($w,$h);
	$self->{layout}->put($widget,$x,$y);
	push @{$self->{r_widgets}},$widget;
    }
    $self->{layout}->thaw();
}

sub render_callback {
    my $self = shift;
    my $event=shift;

    return 1
	    if ($event->{count});    

    if ($self->{pixmap_update}) {
	$self->render_core;
	$self->{pixmap_update}=0;
    }

    my $window=$self->{area}->window;
    $window->set_back_pixmap($self->{pixmap},0);
    $window->clear();

    $self->render_core_r_zones;

    $self->{layout}->show_all;    

    return 1;


}

sub render {

    my $self = shift;

    my $call_gtk_main=0;

    $self->{pixmap_update}=1;
    if (!defined($self->{parent_widget})) {
	if ( ! $PaintDevice::GtkPaintDevice::GTK_INIT) {
	    $PaintDevice::GtkPaintDevice::GTK_INIT=1;
	  Gtk::init($ARGV);
	}	
	$self->{window}=new Gtk::Window -toplevel;
	$self->{window}->set_usize($self->{window_width},
				   $self->{window_height});
	$self->{window}->signal_connect("destroy"=>sub{Gtk::main_quit($self->{window})});
	$call_gtk_main=1;
    } else {
	$self->{window}=$self->{parent_widget};
    }

    if (defined $self->{callback_id}) {
	$self->{window}->signal_disconnect($self->{callback_id});
    }

    if (defined $self->{area}) {
	$self->{layout}->remove($self->{area});
	$self->{area}->destroy();
    }

    if (defined $self->{layout}) {
	$self->{layout}->foreach(sub { shift->destroy();},0);
	$self->{scrolledwindow}->remove($self->{layout});
	$self->{layout}->destroy();
    }

    if (defined $self->{scrolledwindow}) {
	$self->{window}->remove($self->{scrolledwindow});
	$self->{scrolledwindow}->destroy();
    }

    $self->{scrolledwindow}=new Gtk::ScrolledWindow;
#    $self->{scrolledwindow}->set_usize($self->{width},$self->{height});

    $self->{window}->add($self->{scrolledwindow});
    $self->{callback_id}=$self->{window}->signal_connect("expose_event"=>sub{PaintDevice::GtkPaintDevice::render_callback($self)});

    $self->{layout}=new Gtk::Layout(0,0);
    $self->{layout}->set_size($self->{width},$self->{height});
    $self->{scrolledwindow}->add($self->{layout});


    $self->{area}=new Gtk::DrawingArea;
    $self->{area}->size($self->{width},$self->{height});
    $self->{layout}->put($self->{area},0,0);

 
    $self->{scrolledwindow}->show_all;
    if ($call_gtk_main) { 
	$self->{window}->show_all;
      Gtk::main($self->{window});
    }
}

sub set_window_size {
    my $self = shift;
    my $width = shift;
    my $height= shift;
    
    ($self->{window_width},$self->{window_height})=($width,$height);
}

sub text_height {
    my $self = shift;

    return $PaintDevice::GtkPaintDevice::FONT_HEIGHT_POINTS;
}

1
