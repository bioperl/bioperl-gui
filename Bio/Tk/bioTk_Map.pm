############################################################################
#  bioTkperl v0.8
#  Berkeley Drosophila Genome Project
#  Contact gregg@fruitfly.berkeley.edu
#
# Copyright (c) 1995 by Gregg Helt
# (modelled after bioTk1.3, which is copyright (c) 1995 by David B. Searls)
# This software is provided "as is" without express or implied warranty of
# any kind, nor with representations about its suitability for any purpose.
#
############################################################################
#  bioTk_Map.pm
#
#  Modelled after David Searls' bioTk1.3 Map widget
#
###########################################################################

package Bio::Tk::bioTk_Map;

use Bio::Tk::bioTk_Utilities qw(bioTk_ParseArgs);     # this is needed for bioTk_ParseArgs
#@ISA = qw(Tk::Canvas);      # Not sure if this is necessary (or wanted)...
#use Tk::Widget qw(Canvas);  # Not sure is this is necessary...


# use strict 'vars';

Tk::Widget->Construct('bioTk_Map');

$Tk::bioTk_Map::mapNumber = 0;

# Instance Variables (in object's hash table)
#   canvas  -- reference to canvas that map is on
#   (xa, xz, ya, yz)          canvas coordinates defining the 
#                               map area -- THESE HAVE BEEN ELIMINATED
#   canvas_start            canvas coord of the map start  (xa OR ya)
#   canvas_end              canvas coord of the map end    (xz OR yz)
#   canvas_range            canvas_end - canvas_start
#      (canvas_* variables thus serve to abstract away from 
#       the orientation of the map relative to the canvas)
#   map_start (was range[0])   map coord of the map start 
#   map_end   (was range[1])   map coord of the map end
#   map_range                  map_end - map_start
#   (range)    (only for option parsing now -- no longer an instance variable)
#   scale_factor               canvas units per map unit
#   canvas_min   top/left limit of map (perpendicular to axis)  (ya OR xa)
#   canvas_max   bottom/right limit of map ("   "  ")  (yz or xz)
#  etc., etc.
#
#   MapObjects  -- ref to array of arrays of structure:
#                [$center, $min_c_coord, $max_c_coord, $taglist],
#      when &MapInsertLabel is included, can also get [$tab $lbl $lin]
#      MapObjects is currently only used for stairstepping
#
#   MapSpread  -- binary flag, currently only used for stairstepping
#         (also used for 'apart' labelling in Tcl version)
#      
#   MapLabelSize -- not used (only needed for 'apart' labelling in Tcl version)
#

################################################################
#
#  NEW subroutine is anlagous to bioTk_Map in the Tcl version
#
#  Assuming that this is being called as a method on an already 
#    existing canvas (like in Tcl version, but OO)
#   $MapObj = $c->bioTk_Map($xa, $ya, $xz, $yz, options...)
 
sub new { 
    my $package = shift;
    my $class   = $package;
    $class =~ s/^Bio::Tk:://;
    my $parent = shift;
    my $self = {};

    $self->{canvas} = $parent;   # will have to go through this to draw...
    my($xa, $ya, $xz, $yz, $range, $axis_loc);
    my($map_start, $map_end, $canvas_start, $canvas_end,
       $map_range, $canvas_range, $scale_factor,
       $canvas_min, $canvas_max);
    $xa = shift; $ya = shift; $xz = shift; $yz = shift;
    my @args = @_;

    my %ivars = ('orientation' => 'orientation', 'width' => 'width',
		 'linewidth' => 'linewidth', 'color' => 'color', 
		 'unit' => 'unit', 'stairstep' => 'stairstep',
		 'labelfont' => 'labelfont', 'labelcolor' => 'labelcolor',
		 'connect' => 'connect', 'mapping' => 'mapping',
		 'raise' => 'raise', 'icon' => 'icon',
		 'step' => 'step', 'anchor' => 'anchor',
		 'axis_loc'=>'axis_loc');
    my @OptionNames = ('orientation', 'width', 'linewidth', 'color',
		       'anchor', 'unit', 'stairstep', 'labelfont', 
		       'labelcolor', 'connect', 'step', 'mapping', 'range',
		       'raise', 'icon', 'axis_loc');
    
    $self->{orientation} = 'horizontal';
    $self->{width} = 6;
    $self->{linewidth} = 1;
    $self->{color} = 'black';
    $self->{unit} = 'group';
    $self->{stairstep} = 'packed';
    $self->{labelfont} = '-Adobe-Helvetica-Bold-R-Normal--*-120-*';
    $self->{labelcolor} = 'black';
    $self->{'connect'} = '';
    $self->{mapping} = sub { return @{$_[0]}; };   # anonymous default sub
       # just dereferences the arg (presumably an array ref) and returns it
    $self->{raise} = 0;
    $self->{icon} = '';
    $self->{axis_loc} = 0;
   #  Give the map a unique mapIDx tag
    $self->{mapID} = 'mapID'.$Tk::bioTk_Map::mapNumber;
    $Tk::bioTk_Map::mapNumber++;

    eval bioTk_ParseArgs($self, \@args, \@OptionNames, \%ivars);

    # internally switching to 'H' & 'V' for orientation, for efficiency, 
    #   since orientation variable is tested so often
    if ($self->{orientation} eq 'horizontal')  { $self->{orientation} = 'H'; }
    elsif ($self->{orientation} eq 'vertical')  { $self->{orientation} = 'V'; }
    else {print STDERR "Orientation \"$self->{orientation}\" not allowed!\n"; }
    my $orientation = $self->{orientation};

  # Setup instance variables based on orientation, etc.
    if ($orientation eq 'H')  {
	$canvas_start = $xa; $canvas_end = $xz;
	$canvas_min = $ya; $canvas_max = $yz;
	unless ($self->{anchor})  { $self->{anchor} = 's'; }
    }
    elsif ($orientation eq 'V')  {
	$canvas_start = $ya; $canvas_end = $yz;
	$canvas_min = $xa; $canvas_max = $xz;
	unless ($self->{anchor})  { $self->{anchor} = 'e'; }
    }
    else {
	print STDERR "Orientation must be horizontal or vertical: ",
	             "\"$orientation\" is not allowed\n";
	return 0;
    }
    if ($range)  { $map_start = $$range[0]; $map_end = $$range[1]; }
     else { $map_start = $canvas_start; $map_end = $canvas_end; }
    $map_range = $map_end - $map_start;
    $canvas_range = $canvas_end - $canvas_start;
    $scale_factor = $canvas_range / $map_range;       #/

    unless ($self->{step})  { $self->{step} = $self->{width} + 1; }

    $self->{MapSpread} = 0;
    $self->{MapLabelSize} = 0;
    $self->{MapObjects} = [];    # set MapObjects to a ref to an empty array

    $self->{map_start} = $map_start;
    $self->{map_end}   = $map_end;
    $self->{map_range} = $map_range;
    $self->{canvas_start} = $canvas_start;
    $self->{canvas_end} = $canvas_end;
    $self->{canvas_range} = $canvas_range;
    $self->{scale_factor} = $scale_factor;
    $self->{canvas_min} = $canvas_min;
    $self->{canvas_max} = $canvas_max;

    return bless $self, $package;	
}


sub MapAxis  {
    my $self = shift;
    my @args = @_;
    my $canvas = $self->{canvas};
    my($dir, $side, $axis, $lbl, $xt, $yt);
    my($orientation, $linewidth, $color, $labelfont, $mapID, $axis_loc);
    my($map_start, $map_end, $canvas_start, $canvas_end, $scale_factor);
    my($i, $ticks, $units, $offset, $scale, $tags, @othertags, $alltags, $flip);
    $i = -1; $ticks = 0; $units = ''; $offset = 0; $scale = 1;
    # 11/13/98: Added 'nolabels' and 'axis_start' options.  --NH
    my @OptionNames = ('linewidth', 'color', 'ticks', 'scale',
		       'units', 'offset', 'tags', 'flip', 'nolabels', 'axis_start');

    eval &bioTk_ParseArgs($self, \@args, \@OptionNames);

    $orientation = $self->{orientation};
    $linewidth = $self->{linewidth};
    $color = $self->{color};
    $labelfont = $self->{labelfont};
    $mapID = $self->{mapID};
    $axis_loc = $self->{axis_loc};

#    $map_start = $self->{map_start};
    $map_start = $self->{map_start} + $axis_start;
#    print "axis_start = $axis_start, ticks = $ticks, map_start = $map_start\n";  # DEL
    $map_end = $self->{map_end} + $axis_start;
    $canvas_start = $self->{canvas_start};
    $canvas_end = $self->{canvas_end};
    $scale_factor = $self->{scale_factor};

    ### Code for adding extra tags ###
    if (defined($tags))  { 
	my @othertags;
	if (ref($tags))  {
	    my $tag;
	    foreach $tag (@$tags)  { push(@othertags, $tag);  }
	}
	else {@othertags = ($tags); }
	$alltags = [@othertags, 'axis', $mapID];
    }
    else { $alltags = ['axis', $mapID]; }

    #  The reverse direction stuff doesn't seem to work in the Tcl version
    #     (or this version).  The ticks and labels are left out.
    #  MW:  the problem was with the assignment of $labelcolor, which had no value

    if ($orientation eq 'V')  {
		if ($canvas_start > $canvas_end)  { $dir = -1; $side = 'e'; }
		else  { $dir = 1; $side = 'w'; }
		
		$offset = $self->{canvas_min} - $offset*$dir + $axis_loc;
		
		if ($linewidth)  {
	    $axis = $canvas->create('line', 
		$offset, $canvas_start, $offset, $canvas_end,
		'-width' => $linewidth, '-fill' => $color, 
				    '-tags' => $alltags);
		}
    } else  {
		if ($canvas_start > $canvas_end)  { $dir = -1; $side = 'n'; }
		else  { $dir = 1; $side = 's'; }
	
		$offset = $self->{canvas_min} - $offset*$dir + $axis_loc;
		
		if ($linewidth)  {
	    $axis = $canvas->create('line', 
	        $canvas_start, $offset, $canvas_end, $offset,
	        '-width' => $linewidth, '-fill' => $color, 
				    '-tags' => $alltags);
		}
    }

    unless ($linewidth)  { $axis = ''; }
    
    if ($ticks)  {
	for ($i=int($map_start/$ticks)*$ticks;  $i<=$map_end; $i+=$ticks)  {
	    $lbl = ($i/$scale).$units;
	    if ($i>=$map_start)  {
		if ($orientation eq 'H')  {  # horizontal orientation
		    $xt = $canvas_start + $scale_factor*($i-$map_start);
		    if ($flip)  {
    			# print "flipping\n";
    			$xt = $canvas_end - $xt;
		    }
		    $canvas->create('line', $xt, $offset, $xt, $offset-5*$dir,
				    '-width' => $linewidth, '-fill' => $color,
				    '-tags' => $alltags);
		    if (!$nolabels) {
					$canvas->create('text', $xt, $offset-6*$dir,
					 '-anchor' => $side, '-text' => $lbl,
					 '-font' => $labelfont, '-fill' => $color,
					 '-tags' => $alltags);
		    }
		}
		else  {   # vertical orientation
		
		    $yt = $canvas_start + $scale_factor*($i-$map_start);
		    if ($flip)  {
				$yt = $canvas_end - $yt;
			}
		    $canvas->createLine($offset, $yt, $offset-6*$dir, $yt,
				    '-width' => $linewidth, '-fill' => $color,
				    '-tags' => $alltags);
		    if (!$nolabels) {
			 $canvas->createText($offset-20*$dir, $yt,   # MW:  changed it to -20 instead of -6 to prevent writing of labels over the axis
					 '-anchor' => $side,
					 '-text' => $lbl,
					 '-font' => $labelfont,
					 '-fill' => $color,      # MW: this used to be $labelcolor, which had no value so the labels didn't appear on the map
					 '-tags' => $alltags);
		    }
		}
	    }
	}
    }
    return $axis;
}


sub MapObject  {
    my $self = shift;
    my $obj = shift;    # Array of objects
    my @args = @_;
    my @OptionNames = ('at', 'label', 'width', 'linewidth', 
	'color', 'anchor', 'unit', 'stairstep', 'labelfont', 'labelcolor', 
	'connect', 'step', 'mapping', 'range', 'raise', 'icon',
	'ataxis', 'tags', 'just_labels');

    ### Instance variables that can't be overridden in the method call ###
    my($mapID, $canvas, $orientation, $axis_loc, 
       $canvas_start, $canvas_end, $map_start, $map_end, $scale_factor, 
       $canvas_min, $canvas_max, $MapSpread, $MapObjects);

    ### Option variables that default to instance variables ###
    my ($width, $linewidth, $color, $anchor, $unit, $stairstep, 
	$labelfont, $labelcolor, $connect, $step, $mapping, $range, 
	$raise, $icon);

    ### Option variables that can only be specified in the method call
    my($at, $label, $ataxis, $tags, $just_labels);

    ### variables for coordinate calculation ###
    my($min_c_coord, $max_c_coord, $c_coord_first, $c_coord_last, 
       $w2, $dir, $center, $edge1, $edge2, @m_coord, @c_coord);

    ### variables for object rearrangements ###
    my($stepx, $stepy, $move_distance, $dir_plus, $dir_minus, $last, $posn,
       @new, $hit, $lap, @bb, $w, $maxi, $id);

    ### flags for label substitutions ###
    my($label_subs_P, $label_subs_E, $label_subs_N,
       $label_subs_Pn,$label_subs_En,);
#    my($tab);  # for '-apart' option

    ### all the rest of the method variables ###
     # some involved in coords and rearrangements... #
    my($elt, $n, $enum, $prev, $i, $tag_index, $lb, $lbl);

    $canvas = $self->{canvas};
    $orientation = $self->{orientation};
    $width = $self->{width};
    $linewidth = $self->{linewidth};
    $color = $self->{color};
    $anchor = $self->{anchor};
    $unit = $self->{unit};
    $stairstep = $self->{stairstep};
    $labelfont = $self->{labelfont};
    $labelcolor = $self->{labelcolor};
    $connect = $self->{'connect'};  # needed quotes to avoid -w resolution flag
    $step = $self->{step};
    $mapping = $self->{mapping};
    $raise = $self->{raise};
    $icon = $self->{icon};
    $mapID = $self->{mapID};
    $MapObjects = $self->{MapObjects};
    $MapSpread = $self->{MapSpread};

    $canvas_start = $self->{canvas_start};
    $canvas_end = $self->{canvas_end};
    $scale_factor = $self->{scale_factor};
    $axis_loc = $self->{axis_loc};
    $canvas_min = $self->{canvas_min};
    $canvas_max = $self->{canvas_max};

    $i = -1;
#    $at = '';

    eval &bioTk_ParseArgs($self, \@args, \@OptionNames);

    # Range option allows for specification of a different range scaling 
    #  than the range map is set up with, for single calls to MapObject
    #  For now ignoring the possibility that map is reversed, i.e. 
    #     $map_end < $map_start. 
    if ($range)  { $map_start = $$range[0]; $map_end = $$range[1]; }
    else { $map_start = $self->{map_start};  $map_end = $self->{map_end}; }

    ###############  Adding any extra tags  ##############
    #    print "Tags = $tags\n";
    my($alltags, $all_but_sub_tags, @tag_sub_index,
       @alltags, @all_but_sub_tags, @finaltags, $tagsref);
    if (defined($tags))  { 
	if (ref($tags))  { 
	    push(@alltags, @$tags);
	    my $i=-1;
	    foreach (@alltags) {
		$i++;
		if (/\%/) {
		    push(@tag_sub_index,$i);
		} else {
		    push(@all_but_sub_tags, $alltags[$i]);
		}
	    }
	    ###(DB) above 'foreach' instead of below 'for' so that empty loops won't be a problem (DB)
	    #for ($i=0; $i<=$#alltags; $i++)  {
		#if ($alltags[$i] =~ /\%/)  { push(@tag_sub_index,$i); }
		#else  { push(@all_but_sub_tags, $alltags[$i]); }
	    #}
	}
	else { 
	    @alltags = ($tags);
	    if ($tags =~ /\%/)  { @tag_sub_index = (1); }
	    else { @all_but_sub_tags = ($tags); }
	}
	push(@alltags, $mapID, 'new');
	push(@all_but_sub_tags, $mapID, 'new');
        #	print "AllTags = ", @alltags,"\n";
        #	print "AllButSubTags = ", @all_but_sub_tags, "\n";
        #	print "TagSubIndex = ", @tag_sub_index, "\n";
    }
    else { @alltags = ($mapID, 'new'); @all_but_sub_tags = @alltags;  }
    $alltags = \@alltags; $all_but_sub_tags = \@all_but_sub_tags;    
    ########################################################

##### Skipping options at the moment

   ##### Working out boundaries perpendicular to axis #####
    if (defined($at)) {
	if (!(ref($at)))  { $canvas_min = $canvas_max = $at; }
	elsif (ref($at) eq 'ARRAY')  {
	    if ($#$at == 0)  { $canvas_max = $canvas_min = $$at[0]; }
	    else { $canvas_min = $$at[0]; $canvas_max = $$at[1]; }
	}
	elsif ($at eq 'axis')  {  $canvas_min += $axis_loc; 
				  $canvas_max = $canvas_min; }
    }
    elsif (defined($ataxis))  {
	if (ref($ataxis))  {
	    my $temp_min = $canvas_min;
	    $canvas_min = $canvas_min + $axis_loc + $$ataxis[0];
	    if ($#$ataxis == 0)  { $canvas_max = $canvas_min;  } 
	    else  { $canvas_max = $temp_min + $axis_loc + $$ataxis[1]; }
	}
	else  {  $canvas_min = $canvas_min + $axis_loc + $ataxis;
		 $canvas_max = $canvas_min; }
    }
    #  else no -at or -ataxis options, so $canvas_min and $canvas_max 
    #    stay as set in $self->{canvas_min} and $self->{canvas_max}
    if ($canvas_min < $canvas_max) {    
	# start at $canvas_min and move towards $canvas_max
	$dir = 1; }  
    elsif ($canvas_min > $canvas_max)  { 
	# start at $canvas_max and move towards $canvas_min
	$dir = -1; }
    else {
	# $canvas_min equals $canvas_max, don't move at all
        #   dir = 0 flags to not worry about moving objects
	$dir = 0; }
    $step = $dir * $step;   #  added 8/8/95 to allow "reverse" placement
                            #    of objects
    $move_distance = $step;
    $center = $canvas_min;
    $w2 = int($width/2);
    $edge1 = $center-$w2;   # used to be $yb
    $edge2 = $center+$w2;   # used to be $yf
    ##########################################################

  #  Redid these -- they were screwing up the '-connect' option
  #	    $max = 0; $min = 9999999;
  #   $max_c_coord and $min_c_coord are used to determine where to center 
  #       group labels, connect lines, and some stairstepping stuff...
    $max_c_coord = $canvas_start;    # used to be $max
    $min_c_coord = $canvas_end;      # used to be $min
	
    $canvas->dtag('new', 'new');   # last object(s) is no longer new
    if ($raise)  { print "No raise!\n"; exit 0; }
    $prev = 'none';
    $enum = 0;

  #### Setting orientation-specific variables ####
    ## $stepx and $stepy are references to allow orientation-independent
    ##   changing step in stairstepping mode
    if ($orientation eq 'H')  {  # horizontal orientation
	$stepx = \0; $stepy = \$move_distance;
	$dir_plus = 3;  $dir_minus = 1;
    }
    else {                       # vertical orientation
	$stepx = \$move_distance; $stepy = \0;  
	$dir_plus = 2; $dir_minus = 0;
    }
  ################################################

   ### Setting up icon subroutine ref ###
    # should add in 'line' default $icon at some point...
    unless (ref($icon))  {   # if ref then just call ref'ed sub
	if (!$icon) {   # default ($icon = '')
	    $icon = \&MapRectangle; }   # default is rectangle
	elsif ($icon eq 'oval')  { $icon = \&MapOval; }
	elsif ($icon eq 'diamond')  { $icon = \&MapDiamond; }
	elsif ($icon eq 'triangle')  { $icon = \&MapTriangle; }
	elsif ($icon eq 'rectangle') { $icon = \&MapRectangle; }
    }

    ### Setting up label substitution flags ###
    if (defined($label))  {
	if ($label =~ /\%/)  {
	    if ($label =~ /\%[PE]\d/)  {
		if ($label =~ /\%P\d/)  { $label_subs_Pn = 1; }
		if ($label =~ /\%E\d/)  { $label_subs_En = 1; }   }
	    if ($label =~ /\%[PE]\D/)  {
		if ($label =~ /\%P\D/)  { $label_subs_P = 1; }
		if ($label =~ /\%E\D/)  { $label_subs_E = 1; }    }
	    if ($label =~ /\%N/)   { $label_subs_N = 1; }
	}
    }

 ###############  Main loop over each element in the object ###############
    foreach $elt (@$obj)  {
	$enum++;
	@m_coord = &$mapping($elt);   # @m_coord replaces @s from Tcl version
	$n = $#m_coord + 1;

	####  convert map coordinates to canvas coordinates ####
	#  @c_coord replaces $x0, $x1, $x2, $x3 from Tcl version
	@c_coord =  map($canvas_start + $scale_factor * ($_-$map_start),
			@m_coord);
	$c_coord_first = $c_coord[0];         # used to be $x0
	$c_coord_last = $c_coord[$#c_coord];  # used to be $xn (for horizontal)
	if ($n == 4)  {   # object is a span within a span
	    # therefore just want to center group label on inner span
	    if ($c_coord[1] < $min_c_coord)  {$min_c_coord = $c_coord[1];}
	    if ($c_coord[2] > $max_c_coord)  {$max_c_coord = $c_coord[2];}
	}
	else {
	  if ($c_coord_first < $min_c_coord)  {$min_c_coord = $c_coord_first;}
	  if ($c_coord_last > $max_c_coord)  { $max_c_coord = $c_coord_last; }
        }

	### Substitutions for tags ###
	@finaltags = @alltags;
	$tagsref = \@finaltags;
	foreach $tag_index (@tag_sub_index)  {
	    $finaltags[$tag_index] =~ s/\%N/$enum/;  }

	### Substitutions for labels ###
	if (defined($label)) {
	    $lb = $label;
	    if ($label_subs_P)  {
		my $all_mapped_coords = join(', ',@m_coord);	
		$lb =~ s/\%P(\D)/$all_mapped_coords$1/g;   }
	    if ($label_subs_E)  {
		my $all_indirect_refs = join(', ',@$elt);	    
		$lb =~ s/\%E(\D)/$all_indirect_refs$1/g;   }
	    if ($label_subs_N)  { $lb =~ s/\%N/$enum/g; }
	    if ($label_subs_Pn)  { $lb =~ s/\%P(\d)/$m_coord[$1]/g; }
	    if ($label_subs_En)  { $lb =~ s/\%E(\d)/$$elt[$1]/g; }
	}

     ########## Drawing Individual Objects #########
	## all objects initially have tags 'new' and $mapID (in $tagsref)##
	####  Switch: only want label, not object
	if (defined($just_labels))  {  }  # do nothing if just want labels 
	####  object is a point
	elsif ($n == 1)  {  
	    # took out +/- $w2 for $x0 -- I think it should be a point,
	    #    and let the icon sub deal with making it larger if desired
	    &$icon($self, $orientation, 
		       $c_coord[0], $edge1, $c_coord[0], $edge2, 
		       $color, $linewidth, $tagsref);
	}
	####  object is a span
	elsif ($n == 2)  {     
	    &$icon($self, $orientation, 
		       $c_coord[0], $edge1, $c_coord[1], $edge2, 
		       $color, $linewidth, $tagsref); 
	}
	####  object is a point within a span
	elsif ($n == 3)  {
	    &MapRangeBars($self, $orientation, 
			     $c_coord[0], $edge1, $c_coord[2], $edge2, 
			     $color, $linewidth, $tagsref);
	    &$icon($self, $orientation, 
		       $c_coord[1], $edge1, $c_coord[1], $edge2,
		       $color, $linewidth, $tagsref);
	}
	####  object is a span within a span
	elsif ($n == 4)  {
	    &MapSimpleLine($self, $orientation, 
			      $c_coord[0], $center, $c_coord[3], $center,
			      $color, $linewidth, $tagsref);
	    &$icon($self, $orientation, 
		       $c_coord[1], $edge1, $c_coord[2], $edge2, 
		       $color, $linewidth, $tagsref); 
	}
	
	## dealing with drawing splice lines if needed
	if (($prev ne 'none') && ($connect eq 'spliced'))  {
	    &MapSpliceLine($self, $orientation, 
			$prev, $center, $c_coord[0], $edge1,
			$color, $linewidth, $all_but_sub_tags);
	}
	$prev = $c_coord_last;


    ############  Drawing Labels ###########
	if ($label && ($unit eq 'each'))  {
	    for ($i=0; $i<$n; $i++)  {
		# Substitution stuff left out...
	    }
	    # More substitution stuff left out...
	    if ($anchor eq 'apart')  {
#		$self->MapInsertApart($tab, $canvas_start, $canvas_end,
#			   $edge2, $canvas_max, $dir, $lb, $labelcolor,
#			   $labelfont, $color, $orientation);
		print "Apart stuff not implemented yet!\n"; exit 0;
	    }
	    else {
		# Raise stuff left out...
	      $self->MapObjectLabel($canvas, $c_coord_first, $edge1, 
				    $c_coord_last, $edge2,
				    $anchor, $orientation, $lb, $labelfont,
				    $labelcolor, $tagsref );
	    }
	}
    }     # closes foreach $elt
   #################  End of main loop over object elements  #################
        
   ########### Drawing connecting lines ##############
    if ($connect) {    # skip this section if $connect eq ''
	if ($connect eq 'spliced')   { }
	elsif ($connect eq 'dashed')  {
	    $canvas->lower(&MapBrokenLine($self, $orientation, 
				$min_c_coord, $center, $max_c_coord, $center,
				$color, $linewidth, $all_but_sub_tags, 
				'dashed'));
	}
	elsif ($connect eq 'dotted')  {
	   $canvas->lower(&MapBrokenLine($self, $orientation, 
				$min_c_coord, $center, $max_c_coord, $center,
				$color, $linewidth, $all_but_sub_tags,
				'dotted' ) );;
	}
	else  {
	   #  should redo the lower part of this to just lower it below 
	   #   the items currently being mapped -- right now it's being 
	   #   lowered to 1 (rather than to 0/default) so that in 
	   #   applications a selection rectangle can enclose the items 
	   #   and still not obscure the connecting line
	   $canvas->lower(&MapSimpleLine($self, $orientation, 
				  $min_c_coord, $center, $max_c_coord, $center,
				   $connect, $linewidth, $all_but_sub_tags));
	#  had to take out lowering to 1 -- STSTut was having problems, since 
	#    nothing had been mapped yet.
	#			   '-width' => $linewidth), 1);
       }
    }

   ############ Drawing Group labels #############
    if ($label && ($unit eq 'group'))  {
	if ($anchor eq 'apart')  {
#	    $self->MapInsertApart($tab, $canvas_start, $canvas_end,
#				  $edge2, $canvas_max, $dir, $lb, $labelcolor,
#				  $labelfont, $color, $orientation);
		print "Apart stuff not implemented yet!\n"; exit 0;
	}
	else  {     # anchor not apart
	    # left out raise stuff...
	    #  NEED to CHANGE this when label substitution is coded
	    $lbl = $self->MapObjectLabel($canvas, 
				    $min_c_coord, $edge1, $max_c_coord, $edge2,
				    $anchor, $orientation, $lb, $labelfont, 
				    $labelcolor, $all_but_sub_tags );
	}
    }

        
   ############ Rearranging Drawn Items ###############
    if ($dir && ($anchor ne 'apart'))  {
        ##### Rarrange in 'packed' mode (no stairstepping) #####
	if ($stairstep eq 'packed')  {
	    @new = $canvas->find('withtag' => 'new');
	    $hit = 1;
       #  _Really_ should rewrite this section to perlize it
	    while ($hit) {
		$hit = 0;
		foreach $n (@new)  {
		    @bb = $canvas->bbox($n);
		    foreach $lap ($canvas->find('overlapping',@bb))  {
			unless (grep(/$lap/,@new))  { $hit=1; last; }
		    }
		    if ($hit)  { last; }
		}
		if ($hit) { 
		    ## use references to be consistent with stairstepping move
		    $canvas->move('new', $$stepx, $$stepy); }
	      # Checking to see if exceeded allowed area
		@bb = $canvas->bbox('new');
		if ($dir>0) {
		    if ($bb[$dir_plus] > $canvas_max)  { last; }  }
		else {
		    if ($bb[$dir_minus] < $canvas_max)  { last; }  }
	    }
	}

	##### Stairstepping in 'forward'/'backward' mode #####
	else  {      # if $stairstep _not_ 'packed'...
	    $i = 0;
	    foreach $w (@$MapObjects)  {
		if ($stairstep eq 'forward')  {
		    if (($max_c_coord==$$w[2] && $min_c_coord>=$$w[1]) 
			  || $max_c_coord>$$w[2])  {
			last; }
		}
		else {
		    if (($min_c_coord==$$w[1] && $max_c_coord<=$$w[2]) 
			  || $min_c_coord<$$w[1])  {
			last; }
		}
		$i++;
	    }
             #  I think since $MapObjects is a reference, 
	     #  modifying @$MapObjects is effectively modifying 
             #  $self->{MapObjects}, so don't need to reassign it
	    splice (@$MapObjects, $i, 0, 
		    [$center, $min_c_coord, $max_c_coord, 
		     [$canvas->find('withtag'=>'new')] ]);
	    if ($MapSpread)  { $hit =1; }
	    else {
		$hit = 0;
		@new = $canvas->find('withtag' => 'new');
		foreach $n (@new)  {
		    foreach $lap ($canvas->find('overlapping',
						$canvas->bbox($n)))  {
			unless (grep(/$lap/,@new))  { $hit=1; last; }
		    }
		    if ($hit)  { 
			$MapSpread = 1; $self->{MapSpread} = 1; last; }
		}
	    }
	    if ($hit)  {
		my @newobjects;
		#  pushed out the int because of Tcl/Perl division diffs...
		$maxi = int(abs($canvas_min-$canvas_max)/$step);                #/
		$i = 0;
		@newobjects = ();
		foreach $w (@$MapObjects)  {
		    $last = $$w[0];
		    $posn = $canvas_min + ($i%$maxi) * $dir * $step;
		    my $neww = [@$w];
		    $$neww[0] = $posn;
		    push(@newobjects, $neww);
		    $move_distance = $posn-$last;
		    foreach $id (@{$$w[3]})  {
		       # Got rid of orientation dependence here by using
                       #    references -- I'm not sure if this was a good idea 
                       #    though.  It might be clearer if I just did an
		       #    orientation-dependent conditional here...
                       # Differences based on orientation have been set 
                       #        up earlier via references:
		       #  if horizontal, $stepx = \0, $stepy = \$move_distance
		       #  if vertical,   $stepx = \$move_distance, $stepy = \0
		       $canvas->move($id, $$stepx, $$stepy);
		    }
		    $i++;
		}
		$MapObjects = \@newobjects;
		$self->{MapObjects} = $MapObjects;
	    } 
	        
	} # closes 'backward'/'forward' stairstepping option
	    
    }     # closes if ($dir &&....) conditional for rearranging objects

    return $canvas->find('withtag' => 'new');
}


sub MapObjectLabel  {
    my $self = shift;
    my($canvas, $c_start, $c_edge1, $c_end, $c_edge2, 
       $anchor, $orientation, $label, $font, $color, $tags) = @_ ;
    my($x0,$y0,$x1,$y1);
    my($tmp,@data);
    if ($orientation eq 'H')  {
	$x0 = $c_start; $x1 = $c_end;
	$y0 = $c_edge1; $y1 = $c_edge2;    }
    else  { 	
	$x0 = $c_edge1; $x1 = $c_edge2;
	$y0 = $c_start; $y1 = $c_end;      }
	
    if ($x0>$x1) { $tmp = $x0; $x0 = $x1; $x1 = $tmp; }
    if ($y0>$y1) { $tmp = $y0; $y0 = $y1; $y1 = $tmp; }
    $x0 = $x0-2; 
    $x1 = $x1+2;
    #print "x0 = $x0 = $c_start, x1 = $x1 = $c_end\n";
    #print "y0 = $y0 = $c_edge1, y1 = $y1 = $c_edge2\n";
    push @{$tags}, "bioTk_Map_Label";
    @data = ('-text'=>$label, '-font'=>$font, '-fill'=>$color, '-tags'=>$tags);
    if ($anchor eq 'n')  {
        return $canvas->create('text', ($x0+$x1)/2, $y0, '-anchor' => 's',    #/
			       '-justify' => 'center', @data);    }
    elsif ($anchor eq 's')  {
	return $canvas->create('text', ($x0+$x1)/2, $y1, '-anchor' => 'n',        #/
			       '-justify' => 'center', @data);    }
    elsif ($anchor eq 'w')  {
	return $canvas->create('text', $x0, ($y0+$y1)/2, '-anchor' => 'e',        #/
			       '-justify' => 'right', @data);    }
    elsif ($anchor eq 'e')  {
	return $canvas->create('text', $x1, ($y0+$y1)/2, '-anchor' => 'w',         #/
			       '-justify' => 'left', @data);    }
    elsif ($anchor eq 'nw')  {
	if ($orientation eq 'V')  {
	    return $canvas->create('text', $x0, $y0, '-anchor' => 'ne',
				   '-justify' => 'right', @data);  }
	else {
	    return $canvas->create('text', $x0, $y0, '-anchor' => 'sw',
				   '-justify' => 'left', @data);  }
    }
    elsif ($anchor eq 'ne')  {
	if ($orientation eq 'V')  {
	    return $canvas->create('text', $x1, $y0, '-anchor' => 'nw',
				   '-justify' => 'left', @data);  }
	else {
	    return $canvas->create('text', $x1, $y0, '-anchor' => 'se',
				   '-justify' => 'right', @data);  }
    }
    elsif ($anchor eq 'sw')  {
	if ($orientation eq 'V')  {
	    return $canvas->create('text', $x0, $y1, '-anchor' => 'se',
				   '-justify' => 'right', @data);  }
	else {
	    return $canvas->create('text', $x0, $y1, '-anchor' => 'nw',
				   '-justify' => 'left', @data);  }
    }
    elsif ($anchor eq 'se')  {
	if ($orientation eq 'V')  {
	    return $canvas->create('text', $x1, $y1, '-anchor' => 'sw',
				   '-justify' => 'left', @data);  }
	else {
	    return $canvas->create('text', $x1, $y1, '-anchor' => 'ne',
				   '-justify' => 'right', @data);  }
    }
    elsif ($anchor eq 'center')  {
	return $canvas->create('text', ($x0+$x1)/2, ($y0+$y1)/2, 
		         '-anchor'=>'center', '-justify'=>'center', @data);  }
    else { print "Anchor value $anchor not recognized!!\n"; exit 0; }
}


sub MapReset  {
    my $self = shift;
    $self->{MapObjects} = [];
    $self->{MapLabelSize} = 0;
    $self->{MapSpread} = 0;
    return 1;
}


sub MapPosition  {
  #  Usage: $map_coord = $map->MapPosition($canvas_coord)
  #  Returns a map coordinate for a given canvas coordinate
  #
  # Note that orientation doesn't matter -- it's been abstracted
  # For efficiency, should probably just do a return and not assign 
  #     any local variables, but this is much more readable
  # Returns a float -- leave rounding/inting up to the caller
  #    (could add an optional arg for how many decimal places to return...)
    my($self, $canvas_coord, $map_start, $canvas_start, $scale_factor);
    $self = shift;
    $canvas_coord = shift;
    $map_start = $self->{map_start};
    $canvas_start = $self->{canvas_start};
    $scale_factor = $self->{scale_factor};
    return $map_start + ($canvas_coord - $canvas_start) / $scale_factor;
}


sub MapLocation {
  #  Usage: $canvas_coord = $map->MapLocation($map_coord)
  #  Returns a canvas coordinate for a given map coordinate
  #
  # Note that orientation doesn't matter -- it's been abstracted
  # For efficiency, should probably just do a return and not assign 
  #     any local variables, but this is much more readable
  # Returns a float -- leave rounding/inting up to the caller
    my($self, $map_coord, $map_start, $canvas_start, $scale_factor);
    $self = shift;
    $map_coord = shift;
    $map_start = $self->{map_start};
    $canvas_start = $self->{canvas_start};
    $scale_factor = $self->{scale_factor};
    return $canvas_start + $scale_factor * ($map_coord - $map_start);
}


#########################################################################
#
#   Icon Drawing subs
#
#########################################################################

  # Argument list to icon drawing subs:
  #   $self = $_[0];        # the map object
  #   $orientation = $_[1]; # 'H' for horizontal or 'V' for vertical
  #   $c_start = $_[2];   # start of object, along map axis
  #   $c_edge1 = $_[3];   # 1rst boundary of object, perpendicular to map axis
  #   $c_end  =  $_[4];   # end of object, along map axis
  #   $c_edge2 = $_[5];   # 2nd  boundary of object, perpendicular to map axis
  #   $color = $_[6];
  #   $linewidth = $_[7];
  #   $tags = $_[8];

sub MapBrokenLine  {
    my($self, $orientation, $c_start, $c_edge1, $c_end, $c_edge2,
       $color, $linewidth, $tags, $linetype) = @_;
    my($d, $max, $incr, $incr2, $canvas);
    $canvas = $self->{canvas};
    $max = $c_end - $linewidth*5;
    # if $linetype arg not present, use dashed defaults
    if (!$linetype || ($linetype eq 'dashed'))  {
	$incr = $linewidth*5;  $incr2 = $linewidth*3;   }
    elsif ($linetype eq 'dotted')  {
	$incr = $linewidth*3;  $incr2 = $linewidth;   }
    ### should add option for $linetype = [$incr $incr2]
    if ($orientation eq 'H')  {
	for ($d=$c_start+$linewidth; $d<$max; $d+=$incr)  {
	    $canvas->create('line', $d, $c_edge1, $d+$incr2, $c_edge2,
		       '-tags'=>$tags, '-fill'=>$color, '-width'=>$linewidth);
	}
    }
    else  {
	for ($d=$c_start+$linewidth; $d<$max; $d+=$incr)  {
	    $canvas->create('line', $c_edge1, $d, $c_edge2, $d+$incr2,
		       '-tags'=>$tags, '-fill'=>$color, '-width'=>$linewidth);
	}
    }
}

sub MapTriangle  {
    my($self, $orientation, $c_start, $c_edge1, $c_end, $c_edge2,
       $color, $linewidth, $tags) = @_;
    my $axis_mid = ($c_start + $c_end)/2;
    if ($orientation eq 'H')  {
	$self->{canvas}->create('polygon', $c_start, $c_edge2, 
				$axis_mid, $c_edge1, $c_end, $c_edge2,
				'-fill'=>$color, '-tags'=>$tags);
    }
    else {
	$self->{canvas}->create('polygon', $c_edge2, $c_start,
				$c_edge1, $axis_mid, $c_edge2, $c_end,
				'-fill'=>$color, '-tags'=>$tags);
    }
}

sub MapDiamond  {
    my($self, $orientation, $c_start, $c_edge1, $c_end, $c_edge2,
       $color, $linewidth, $tags) = @_;
    my($axis_mid, $edge_mid);
    $axis_mid = ($c_start + $c_end)/2;
    $edge_mid = ($c_edge1 + $c_edge2)/2;
    if ($orientation eq 'H')  {
	$self->{canvas}->create('polygon', 
				$c_start, $edge_mid, $axis_mid, $c_edge1,
				$c_end, $edge_mid, $axis_mid, $c_edge2,
				'-fill'=>$color, '-tags'=>$tags);
    }
    else  {
	$self->{canvas}->create('polygon', 
				$edge_mid, $c_start, $c_edge1, $axis_mid,
				$edge_mid, $c_end, $c_edge2, $axis_mid,
				'-fill'=>$color, '-tags'=>$tags);
    }
}	

sub MapOval  { 
    my($self, $orientation, $c_start, $c_edge1, $c_end, $c_edge2,
       $color, $linewidth, $tags) = @_;
    # adjust start and end if object is "too" small
    if (abs($c_start-$c_end) < 6)  { 
	my $c_mid = ($c_start + $c_end) / 2;
	$c_start = $c_mid - 3; $c_end = $c_mid + 3;
    }
    if ($orientation eq 'H')  {
	$self->{canvas}->create('oval', $c_start, $c_edge1, $c_end, $c_edge2,
				'-fill'=>$color, '-outline'=>undef,
				'-tags'=>$tags);
    }
    else {
	$self->{canvas}->create('oval', $c_edge1, $c_start, $c_edge2, $c_end,
				'-fill'=>$color, '-outline'=>undef,
				'-tags'=>$tags);
    }
}


sub MapRectangle  {
  #  Could assign my vars, but will use straight @_ list for efficiency
  #   Never mind, switched back to assigned vars
  #  Actually, this doesn't seem to matter -- I think the time spent 
  #    assigning "my" variables is minor compared to the time spent in the
  #    Tk canvas 'create' subs
    my($self, $orientation, $c_start, $c_edge1, $c_end, $c_edge2,
       $color, $linewidth, $tags) = @_;

    if($orientation eq 'H')  {   # orientation is horizontal
	# therefore start/end are x coords, edges are y coords
	$self->{canvas}->create('rectangle', 
				$c_start, $c_edge1, $c_end, $c_edge2,
		                '-fill' => $color, '-outline' => undef, 
				'-tags' => $tags);
    }
    else {  # orientation is vertical
	# therefore start/end are y coords, edges are x coords
	$self->{canvas}->create('rectangle', 
				$c_edge1, $c_start, $c_edge2, $c_end,
				'-fill' => $color, '-outline' => undef,
				'-tags' => $tags);
    }
}

sub MapSimpleLine {
    my($self, $orientation, $c_start, $c_edge1, $c_end, $c_edge2,
       $color, $linewidth, $tags) = @_;
    if ($orientation eq 'H')  {
        $self->{canvas}->create('line', $c_start, $c_edge1, $c_end, $c_edge2,
				'-fill'=> $color, '-width'=> $linewidth,
				'-tags'=> $tags);
    }
    else  {
	$self->{canvas}->create('line', $c_edge1, $c_start, $c_edge2, $c_end,
				'-fill'=> $color, '-width'=> $linewidth,
				'-tags'=> $tags);
    }
}

sub MapSpliceLine  {
    my($self, $orientation, $c_start, $c_edge1, $c_end, $c_edge2,
       $color, $linewidth, $tags) = @_;
    if ($orientation eq 'H')  {
	$self->{canvas}->create('line', $c_start, $c_edge1, 
			       ($c_start+$c_end)/2, $c_edge2, $c_end, $c_edge1,
				'-tags' => $tags, '-fill' => $color,
				'-width' => $linewidth, '-capstyle'=>'round');
    }
    else  {
	$self->{canvas}->create('line', $c_edge1, $c_start,
			       $c_edge2, ($c_start+$c_end)/2, $c_edge1, $c_end,
				'-tags' => $tags, '-fill' => $color,
				'-width' => $linewidth, '-capstyle'=>'round');
    }
}

sub MapRangeBars  {
    my($self, $orientation, $c_start, $c_edge1, $c_end, $c_edge2,
       $color, $linewidth, $tags) = @_;
    my($canvas, $mid);
    $canvas = $self->{canvas};
    $mid = ($c_edge1 + $c_edge2) / 2;
    if ($orientation eq 'H')  {    # horizontal orientation
	$canvas->create('line', $c_start, $mid, $c_end, $mid, 
			'-fill'=>$color, '-width'=>$linewidth, '-tags'=>$tags);
	$canvas->create('line', $c_start, $c_edge1, $c_start, $c_edge2,
			'-fill'=>$color, '-width'=>$linewidth, '-tags'=>$tags);
	$canvas->create('line', $c_end, $c_edge1, $c_end, $c_edge2,
			'-fill'=>$color, '-width'=>$linewidth, '-tags'=>$tags);
    }
    else  {           # vertical orientation
	$canvas->create('line', $mid, $c_start, $mid, $c_end, 
			'-fill'=>$color, '-width'=>$linewidth, '-tags'=>$tags);
	$canvas->create('line', $c_edge1, $c_start, $c_edge2, $c_start,
			'-fill'=>$color, '-width'=>$linewidth, '-tags'=>$tags);
	$canvas->create('line', $c_edge1, $c_end, $c_edge2, $c_end,
			'-fill'=>$color, '-width'=>$linewidth, '-tags'=>$tags);
    }
}


###########################################################
#  Debugging subroutines

sub prMapObjects  {
    my $MapObjects = shift;
    my $obj;
    print "MapObjects: ";
    foreach $obj (@$MapObjects) { &prMapObject($obj); }
    print "\n";
}

sub prMapObject {
    my $obj = shift;
    my $el;
    print "{";
    print "$$obj[0] $$obj[1] $$obj[2] ";
    print "{";
    foreach $el (@{$$obj[3]})  { print "$el "; }
    print "}";
    print "} ";
}


1;

__END__

#########  Bits of work in progress  ##########
# starting work on '-apart' option subs
sub MapInsertApart  {
    my ($self, $tab, $canvas_start, $canvas_end, $edge2, $canvas_max, 
	$dir, $lb, $labelcolor, $labelfont, $color, $orientation) = @_;
    my($canvas, $MapObjects);
    my($lbl, $lin);
    $canvas = $self->{canvas};
    $MapObjects = $self->{MapObjects};
    $lbl = $canvas->create('text', $tab, $canvas_max+4*$dir, '-anchor'=>'n',
			   '-tags'=>['new',$mapID], '-justify'=>'center',
			   '-text'=>$lb, '-fill'=>$labelcolor, 
			   '-font'=>$labelfont);
    $line = $canvas->create('line', $tab, $edge2, $tab, $canvas_max, 
			    '-fill'=>$color, '-tags'=>['new',$mapID]);

}
# $tab stuff, only used for labels with '-apart' option
	    $tab = $$c_coord[0];  # n == 1
	    $tab = ($c_coord[1]-$c_coord[0])/2;  # n == 2
	    $tab = $c_coord[1];   # n == 3
	    $tab = ($c_coord[2] - $c_coord[1])/2;  # n == 4

