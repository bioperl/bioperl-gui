############################################################################
#  bioTkperl v0.8
#  Berkeley Drosophila Genome Project
#  Contact gregg@fruitfly.berkeley.edu
#
#  Copyright (c) 1995 by Gregg Helt
#  This software is provided "as is" without express or implied warranty of
#  any kind, nor with representations about its suitability for any purpose.
#
############################################################################
#  AnnotMap.pm
#  a specialized annotated map widget, 
#     inheriting from bioTk_Map and adding a zooming method
#     (this will eventually be incorporated into bioTk_Map)
#
############################################################################

use Bio::Tk::bioTk_Map;

package Bio::Tk::AnnotMap;

@ISA = qw(Bio::Tk::bioTk_Map);
# (bless \qw(AnnotMap))->WidgetClass;   # for earlier versions of TkPerl
Tk::Widget->Construct('AnnotMap');

sub new {
    my $class = shift;
    my $self = new Bio::Tk::bioTk_Map(@_);
    return bless $self;
}

sub Zoom  {
    my $self = shift;
    my $zoom_factor = shift;
    my $current_loc = shift;
    my($canvas, $mapID, $canvas_range, $scale_factor,
       $map_range);
    my($canvas_start, $diff_to_start); 
    my($canvas_end, $diff_to_end);

    $canvas = $self->{canvas};
    $mapID = $self->{mapID};
    $map_range = $self->{map_range};
    $canvas_range = $self->{canvas_range};
    $canvas_start = $self->{canvas_start};
    $canvas_end = $self->{canvas_end};

    $canvas_range = $canvas_range * $zoom_factor;
    $scale_factor = $canvas_range / $map_range;   #/

    if ($self->{"orientation"} eq "V") {   # added by Mark Wilkinson to accomodate vertical versus horizontal maps
    	$canvas->scale($mapID, 0, $current_loc, 1, $zoom_factor);
	} else {
	    $canvas->scale($mapID, $current_loc, 0, $zoom_factor, 1);
	}
	
    $diff_to_start = $current_loc - $canvas_start;
    $diff_to_end = $canvas_end - $current_loc;
    $canvas_start = $current_loc - ($zoom_factor * $diff_to_start);
    $canvas_end = $current_loc + ($zoom_factor * $diff_to_end);
	
    $self->{canvas_range} = $canvas_range;
    $self->{scale_factor} = $scale_factor;
    $self->{canvas_start} = $canvas_start;
    $self->{canvas_end} = $canvas_end;
    if ($self->{"orientation"} eq "V") {
    $canvas->configure('-scrollregion' =>
		    [$self->{canvas_min}, $canvas_start,
		     $self->{canvas_max}, $canvas_end] );

    } else {        # added by Mark Wilkinson to accomodate vertical vs horizontal maps
    $canvas->configure('-scrollregion' =>
		    [ $canvas_start, $self->{canvas_min},
		     $canvas_end, $self->{canvas_max} ] );
	}
}

1;

