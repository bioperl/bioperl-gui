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
###########################################################################
#  bioTk_Sequence.pm
#
#  A port of David Searls' bioTk1.3 Sequence widget
#
###########################################################################

# use strict vars;

package Bio::Tk::bioTk_Sequence;

# Removed reliance on Composite (since this class is no longer in part of 
#   TkPerl, and it's not necessary), and Frame (since it's not necessary -- 
#   at least for now) -- 7/30/95
#@ISA = qw(Tk::Composite Tk::Canvas);
#use Tk::Widget qw(Frame Canvas);

#@ISA = qw(Tk::Canvas);
#use Tk::Widget qw(Canvas);
use Bio::Tk::bioTk_Utilities;     # this includes bioTk_TclDiv and
			     #   bioTk_ParseArgs
# use strict 'vars';
# print "Using bioTk_Sequence, v0.8\n";
# WidgetClass is obsolete, at least as of beta7
# (bless \qw(bioTk_Sequence))->WidgetClass;
Tk::Widget->Construct('bioTk_Sequence');

#--------- set class variables (and defaults) --------
$DefaultWidth = 100;
$DefaultHeight = 25;
$DefaultLineSpace = 1;
$DefaultBackground = 'azure2';
$DefaultSeqHighlightColor = 'wheat1';
$DefaultSeqFont = "*-courier-medium-r-normal--*-120-*-*-*-*-*-*";
$DefaultLabelFont = "*-helvetica-bold-r-normal--*-120-*-*-*-*-*-*";
$cursor = 'plus';

sub new  {
    my $package = shift;
    my $class   = $package;
    $class =~ s/^Bio::Tk:://;
    my $parent = shift;
#  Removed frame stuff 7/30/95
#    my $f = $parent->Frame();
#    my $c = $f->Canvas();
    my $c = $parent->Canvas();
    my @args = @_;
    my(@tempbbox, $background, $SeqFont, $height, $barcolor,
       $SeqWidth, $SeqLabelFont, $sample, $SeqFontWidth, $SeqFontHeight,
       $SeqLineWidth, $i);
    my $none;    # An undefined dummy variable to get around the problem with 
                 # using a null variable to prevent drawing of outlines
    my($yview);
  # Hit some weirdness here.  I wanted to go ahead and bless $c so that 
  #   I could call methods on it now (like making bioTk_ParseArgs into
  #   a method call).  But if I "bless $c,$package" at this point, something
  #   goes wrong with the $f and $c packing calls and I get an error.  I can 
  #   get around this by moving the following two lines up above the bless:
  #         $c->pack('-side' => 'top');	
  #         $c->{Frame} = $f;
  #   However, I'm not convinced that there won't be other problems I just 
  #   haven't seen yet.  So for now, I'm explicitly passing in a $widget 
  #   argument to bioTk_ParseArgs (which then modifies the $widget's 
  #   instance variable hash table, and returns a string to eval for setting 
  #   local/my variables).

    my %ivars = ('width' => 'SeqWidth', 'height' => 'height',
		 'linespace' => 'SeqLineSpace', 'background' => 'background',
		 'bars' => 'barcolor', 'sequencefont' => 'SeqFont',
		 'labelfont' => 'SeqLabelFont', 
		 'yscrollcommand' => 'yscrollcommand' );
    my @OptionNames = ('width', 'height', 'linespace', 'background','bars',
		    'sequencefont', 'labelfont', 'yscrollcommand');

 #  use bioTk_ParseArgs from my Tk::MyUtilities
    eval &bioTk_ParseArgs($c, \@args, \@OptionNames, \%ivars);

    unless ($c->{SeqWidth})       { $c->{SeqWidth} = $DefaultWidth; }
    unless ($c->{height})         { $c->{height} = $DefaultHeight; }
    unless ($c->{SeqLineSpace})   { $c->{SeqLineSpace} = $DefaultLineSpace; }
    unless ($c->{background})     { $c->{background} = $DefaultBackground; }
    unless ($c->{barcolor})       { $c->{barcolor} = $DefaultBackground; }
    unless ($c->{SeqFont})        { $c->{SeqFont} = $DefaultSeqFont; }
    unless ($c->{SeqLabelFont})   { $c->{SeqLabelFont} = $DefaultLabelFont; }

    $background = $c->{background};
    $SeqFont = $c->{SeqFont};
    $height = $c->{height};
    $barcolor = $c->{barcolor};
    $SeqWidth = $c->{SeqWidth};
    $SeqLabelFont = $c->{SeqLabelFont};

####  Error Handling 
    # includes all the error-handling in bioTk_Sequence, except
    #      check for $c's previous existence
    #      check for unknown options is already dealt with in bioTk_ParseArgs

    if (($SeqWidth % 10) != 0)  {
	print "bioTk_Sequence: width must be a multiple of 10\n"; return 0; }
####    

    $c->configure('-background' => $background,
                       '-relief' => 'flat',
                       '-cursor' => $cursor);
    if (defined($yview))  { $c->configure('-yview' => $yview); }
    $sample = $c->create('text', 0, 0, '-anchor'=> 'sw', 
                         '-text' => 'gatcgatcgatcgatcgatcgatcgatcgatcgatcgatc',
                         '-font' => $SeqFont) ;

    @tempbbox = $c->bbox($sample);
    $SeqFontWidth =  ($tempbbox[2] - 2) / 40 ;
    $SeqFontHeight = int( 1 - $tempbbox[1] );
    $SeqLineWidth = $SeqWidth * $SeqFontWidth + 70;
    $c->{SeqFontHeight} = $SeqFontHeight;
    $c->{SeqFontWidth} = $SeqFontWidth;
    $c->delete($sample);

    $c->configure('-width' => $SeqLineWidth, 
                  '-height' => ($height * $SeqFontHeight + 30), 
                  '-scrollregion' => [0, 0, $SeqLineWidth, 1]  );

 # Setting up the top rectangle to hold header marks and number text
  #Couldnt get it to accept "" as a color for outline, for now
  # the outlines (if needed) are set to the same color as the fill
    $c->create('rectangle', 0, 0, $SeqLineWidth, 26, 	
               '-fill' => $background,  '-outline' => $none,
               '-tags' => 'bioTk_SeqNoScroll');

# Creating the header marks and number text up at the top
#  First the ones to display when the sequence is positively numbered
    for ($i=10; $i <= $SeqWidth; $i+=10)  {
	$c->create('text', (58+$i*$SeqFontWidth), 10, 
		   '-text' => $i, '-anchor' => 'e', '-font' => $SeqLabelFont,
		   '-tags' => ['bioTk_SeqNoScroll','positiveheads']  );
	$c->create('line', (53+$i*$SeqFontWidth), 17, 
		           (53+$i*$SeqFontWidth), 23,
		   '-tags' => ['bioTk_SeqNoScroll','positiveheads']  );
	if (($i%20) == 10)  {
	    $c->create('rectangle', (57+$i*$SeqFontWidth), 0, 
		       57 + ((($i-10)>0)?($i-10):0) * $SeqFontWidth, 999999,
		       '-fill' => $barcolor, '-outline' => $barcolor,
		       '-tags' => 'bars');
	}
    }

# Now the ones to display when the sequence is negatively numbered
    for ($i=11; $i < $SeqWidth; $i+=10)   {
	$c->create('text', (54+$i*$SeqFontWidth), 10, 
		   '-text' => ($i-$SeqWidth-1), '-anchor' => 'c',
		   '-tags' => ['bioTk_SeqNoScroll','negativeheads'] );
	$c->create('line', (53+$i*$SeqFontWidth), 17, 
		           (53+$i*$SeqFontWidth), 23,
		   '-tags' => ['bioTk_SeqNoScroll','negativeheads'] );
    }
    $c->move('negativeheads', 0, -99999);
    $c->{SeqHeaderSign} = 'positive';
    $c->lower('bars');

# This stuff differs because the proc bioTk_Sequence() has now
# become the bioTk_Sequence method new()

# removed frame stuff 7/30/954
#    $c->pack('-side' => 'top');	
#    $c->{Frame} = $f;   
    return bless $c, $package;	
}


#-------------------------------------------------------
# Removed pack stuff 7/30/95, now just inheriting pack from Canvas
#sub pack  {
#    my $c = shift;
#    my $f = $c->{Frame};
#    $f->pack(@_);	       
#}

#-------------------------------------------------------
sub PutSequence {
    my $c = shift;
    my $seq = shift;
    my @args = @_;
    my $SeqWidth = $c->{SeqWidth};
    my $SeqFontHeight = $c->{SeqFontHeight};
    my $SeqFontWidth =  $c->{SeqFontWidth};
    my $SeqLineSpace =  $c->{SeqLineSpace};
    my $SeqLabelFont = $c->{SeqLabelFont};
    my $SeqFont =      $c->{SeqFont};
    my ($seqlength, $start, $linenum, $linelabel, $prelen, $line, 
	$posn, @SeqMarkers);
#    print "SW -- $SeqWidth, SFH -- $SeqFontHeight, SFW -- $SeqFontWidth, ",
#        "SLS -- $SeqLineSpace, SLF -- $SeqLabelFont, SF -- $SeqFont\n";

    $c->{Sequence} = $seq;   # I don't think Sequence is used in this sub...
    $c->move('bioTk_SeqNoScroll', 0, -9999);
    $c->delete($c->find('enclosed', -1, -5, 99999, 999999));
    $start = 1;
    my %ivars = ('start' => 'SeqStart');
    my @OptionNames = ('start');
    eval &bioTk_ParseArgs($c, \@args, \@OptionNames, \%ivars);
  
####  Error Checking
    if (($start == 0) || !($start =~ /^-?[0-9]+$/))  {
	print "bioTk_Sequence->PutSequence: start position must be ",
        	"a non-zero integer\n";
	return 0;
    }
####

    if ($start<0) { $start++; }
    $linenum = 1;

# Need Tcl "/" operand sub because of truncation wierdness
#   Rewrote to use a general bioTk_TclDiv function (in Tk::MyUtilities)
    $linelabel = &bioTk_TclDiv($start-1,$SeqWidth) * $SeqWidth;
    $prelen = $SeqWidth - ($start - $linelabel - 1);

# -----------  Start of loop to draw sequence -------------
    $seqlength = length($seq);		
    while ($seqlength > 0)  {
	$line = "";
	$line .= substr($seq, 0, $prelen);
	if ($seqlength < $prelen)  { $seq = ""; }
	else  {	$seq = substr($seq, $prelen); }
	$seqlength = length($seq);

	$posn = ($linenum-1) * $SeqFontHeight * $SeqLineSpace +
	          $SeqFontHeight + 25;
        $c->create('text', 52, ($posn-$SeqFontHeight/2.5), 
		   '-font' => $SeqLabelFont, '-anchor' => 'e',
		   '-text' => (($linelabel<0)?$linelabel:($linelabel+1))  );
	$c->create('text', 57+($SeqWidth-$prelen)*$SeqFontWidth,
			    $posn, '-tags' => "SeqLine$linelabel",
			    '-font' => $SeqFont, '-anchor' => 'sw',
			    '-text' => $line );
	$c->create('line', -1, $posn-5, -2, $posn-5);
	$prelen = $SeqWidth;
	$linelabel += $SeqWidth;
	$linenum++;
    }
    $c->{SeqStart} = ($start>0)?($start-2):($start-1);

    $c->configure('-scrollregion',
		  [0, 0, ($SeqWidth*$SeqFontWidth + 70), $posn]);

    $c->move('bioTk_SeqNoScroll', 0, 9999);
    $c->raise('bioTk_SeqNoScroll');
    @SeqMarkers = $c->find('overlapping', -1, 30, -2, 99999);
    $c->{SeqMarkers} = \@SeqMarkers;
    $c->SequenceGoTo($start);
    return 1;
}


#----------------------------------------------------------------
sub SequenceGoTo {
    my $c = shift;
    my $index = shift;
    my $SeqWidth = $c->{SeqWidth};
    my $SeqFontHeight = $c->{SeqFontHeight};
    my $SeqHeaderSign = $c->{SeqHeaderSign};
    my @SeqMarkers = @{$c->{SeqMarkers}} ;
    my($mark, @temp, $temp, $tempindex);
    my $at = $c->canvasy(0);
    my $line = $c->SequencePosition(60, $c->canvasy(30));
    $mark = "";
#  Acckkk!!! got burned here by array access differences
#   apparently, in Tcl [lindex $array -negativenumber] returns "",
#   whereas in Perl $array[$negativenumber] regurns the array element 
#   counting _back_ $negativenumber from the end of the array

    $tempindex = int(&bioTk_TclDiv($index-1,$SeqWidth));

    unless ($tempindex < 0)  { $mark = $SeqMarkers[$tempindex]; }
    if ($mark eq "")  { 
	$mark = $SeqMarkers[0]; }
    my $posn = ($c->coords($mark))[1];

    @temp = $c->yview();
    @temp = $c->configure('-scrollregion');
    $temp = ($posn-$SeqFontHeight-20.5) / (@{$temp[4]})[3] ;
    $c->yview('moveto', $temp);
    $c->move('bioTk_SeqNoScroll', 0, ($c->canvasy(0))-$at );
    if (($c->SequencePosition(50,30)) >= 0)   {
	if ($SeqHeaderSign eq 'negative')   {
	    $c->move('positiveheads', 0, 99999);
	    $c->move('negativeheads', 0, -99999);
	    $SeqHeaderSign = 'positive';
	    $c->{SeqHeaderSign} = 'positive';
	}
    }
    else {
	if ($SeqHeaderSign eq 'positive')  {
	    $c->move('positiveheads', 0, -99999);
	    $c->move('negativeheads', 0, 99999);
	    $SeqHeaderSign = 'negative';
	    $c->{SeqHeaderSign} = 'negative';
	}
    }

}

#---------------------------------------------------------------------
sub SequencePosition {
    my $c = shift;
    my $x = shift;
    my $y = shift;
    my $mark = shift;
    my $SeqFontWidth = $c->{SeqFontWidth};
    my($linelbl, $index, $length, $inseqid, @tags, $tag, @temp, $var);
    if ($mark)  {
	if ($mark eq '-mark')  {
	    $var = shift;
	    unless (ref($var) eq 'SCALAR')  {
		print "bioTk_Sequence->SequencePosition: ",
		"Mark arg must be reference to a scalar\n";
		return 0;
	    }
	}
	else  { print "bioTk_Sequence->SequencePosition ",
		      "unrecognized option $mark\n";
		return 0;
	    }		       
    }


    $y = int($c->canvasy($y));
    foreach $inseqid  ($c->find('overlapping', 55, $y, 999999, $y))    {
#    foreach $inseqid  ($c->find('overlapping', 55, $y+5, 999999, $y-5))    {
#    foreach $inseqid  ($c->find('closest', 55, $y, 999999, $y))    {
#    foreach $inseqid  ($c->find('closest', 55, $y, 999999, $y))    {
	@tags = $c->gettags($inseqid);
      # This is the first thing I could come up with to emulate Tcl's lsearch
      #    kinda strayed from the Tcl version in this section...
      # Could have used grep(pattern, @tags) whenever need to emulate Tcl's
      #   lsearch, but I'm more comfortable with this looping approach
      	foreach $tag (@tags)  {
	    if ($tag =~ /^SeqLine(\-*\d+)$/ )  {
		$linelbl = $1;
		$index = $c->index($inseqid, "\@$x,$y");
		$length = ($c->index($inseqid, "\@999999,$y")) -
   		          ($c->index($inseqid, "\@0,$y"))  ;
		if ($index >= $length)   { $index--; }
		@temp = $c->coords($inseqid);
		$index += int(&bioTk_TclDiv( $temp[0]-57.0,  $SeqFontWidth));
		$index += $linelbl;
		$index = ($index>=0)?($index+1):$index ;
		if (defined($var))  { $$var = $index; }
		return $index;
	    }
	}
    }
    return 0;
}    


sub SequenceScroll  {
    my $c = shift;
    my $ScrollCommand = $_[0];
    my @args = @_;
    my($at,$mv,@temp,$goto,$temp);
    my $SeqWidth = $c->{SeqWidth};
    if ($ScrollCommand eq 'goto')  {
	$c->SequenceGoTo($args[1]);
	return;
    }
    elsif ($ScrollCommand eq 'moveto')  {
	$at = $c->canvasy(0);
	$c->yview('moveto', $args[1]);
	$c->move('bioTk_SeqNoScroll', 0, (($c->canvasy(0))-$at));
	$mv = 0;
    }
    elsif ($ScrollCommand eq 'scroll')  {
	if    ($args[2] eq 'units')  { $mv = $args[1]; }
	elsif ($args[2] eq 'pages')  { $mv = $args[1] * 10; }
    }

    @temp = $c->find('overlapping', -1, 30, -2, $c->canvasy(30));
    if ($#temp < 0) {$temp=0;} else {$temp=$#temp + 1;}
    $goto = (1 + $mv + $temp) * $SeqWidth  ;
#    print "GoTo: $goto   mv: $mv   templength: $temp\n";
    $c->SequenceGoTo($goto)  ;
}


sub SequenceMakeRoom  {
    my $c = $_[0];
    my $lblid = $_[1];
    my $markid = $_[2];
    my($id, @tags, $seqid, $t, $noscroll, $tag, @tags2, $tag2);
    my $SeqWidth = $c->{SeqWidth};
    my $SeqFontHeight = $c->{SeqFontHeight};
    my @box = $c->bbox($lblid);

    # Right now, the TkPerl version of $c->bbox() is giving a slightly larger
    #  bounding box than the Tcl version, with the result that the bbox around 
    #  the annotation label and marker ends up overlapping not only the 
    #  sequence directly underneath it, but also the sequence just below it. 
    #  So SequenceMakeRoom ends up moving the sequence down one 
    #  $SeqFontHeight too many.  At the moment to fix this I'm going to just 
    #  shrink the bounding box a little once it comes back...

    $box[3] += -2.5;    # This makes $box[3] = what's returned in Tcl
                        #   version of bbox, at least in a test case

    foreach $id ($c->find('overlapping',@box))  {
	@tags = $c->gettags($id);
        # Somwhat rewrote the rest because the bioTk1.2 version relied 
        #   heavily on Tcl's 'lsearch' command
	$seqid = 0;	       
	foreach $tag (@tags) 
        	{ if ($tag =~ /^SeqLine(\-*\d+)$/)  {$seqid=$1; last;}    }
	if ($seqid ne 0)  {
	    foreach $t ($c->find('enclosed', -5, 
  			         (($c->coords($id))[1]) - $SeqFontHeight - 4.5,
				 9999, 99999)  )    {
		if (($t ne $lblid) && ($t ne $markid))  {
		    $noscroll = 0;
		    @tags2 = $c->gettags($t);
		    foreach $tag2 (@tags2)  {
			if ($tag2 eq 'bioTk_SeqNoScroll')  { $noscroll = 1; last; }
			if ($tag2 eq 'bars') { $noscroll = 1; last; }
		    }
		    $c->move($t,0,$SeqFontHeight) unless ($noscroll);
		    
		    
		}
	    }
	    $c->SequenceMakeRoom($lblid,$markid);
	    last;
	}
    }
}


    
sub SequenceLocation {
    my $c = $_[0];
    my $index = $_[1];
    my $SeqWidth = $c->{SeqWidth};
    my $SeqFontWidth = $c->{SeqFontWidth};
    my($x, $y, $linelbl, $linenum);
    if ($index>0)  { $index--; }
    $x = 51 + $SeqFontWidth * (1+$index%$SeqWidth) ;
    $linelbl = int(&bioTk_TclDiv($index,$SeqWidth)) * $SeqWidth;
    $linenum = int(&bioTk_TclDiv($index,$SeqWidth)) + 1;
    $y = ($c->coords("SeqLine$linelbl"))[1];
    if ($y ne "")   { return ($x, $y, $linenum) }  else  {return 0;}
}


sub SequenceDrawAnnotation  {
    my $c = shift;
    my($x0, $x1, $level, $color, $label, $tagtag, $type) = @_;
    my($markid, $lblposn, $lblid, $under, $over, $clash, @box, $lap, 
       $tag, @tags, $loopnum);
    my($SeqLabelFont) = $c->{SeqLabelFont};
    my($SeqWidth) = $c->{SeqWidth};
    my($SeqFontWidth) = $c->{SeqFontWidth};
    
    $c->move('bars', -9999, 0);	
    $markid = $c->create('line', $x0, $level, $x1, $level, 
			 '-fill' => $color, '-width' => 2, '-tags' => $tagtag,
			 '-capstyle' => 'round', '-arrow' => $type,
			 '-arrowshape' => [5, 5, 2]  );
    $lblposn = ($x0 + $x1) / 2;
    $lblid = $c->create('text', $lblposn, $level, '-anchor' => 'n', 
			'-font' => $SeqLabelFont, '-text' => $label, 
			'-tags' => $tagtag);
    $under = 45 - ($c->bbox($lblid))[0];
    if ($under > 0)   { $c->move($lblid, $under, 0); }
    $over = $SeqWidth * $SeqFontWidth + 70 - ($c->bbox($lblid))[2] ;
    if ($over < 0)   { $c->move($lblid, $over, 0); }

    $c->SequenceMakeRoom($lblid,$markid);

# Now look for clashes with other annotations 
#   (well, actually anything that's not a SeqLine)
    $clash = 0;
#  Fixed bug of overlapping marks with previous labels -- 8/3/95
#   @box = $c->bbox($lblid);
    @box = $c->bbox($lblid,$markid);
#    foreach $temp (@box)  { print "$temp "; }  print "\n";
    $box[3] += -2.5;	#   This makes $box[3] = what's returned in Tcl
                        #   version of bbox, at least in a test case
  LAPLOOP:
    foreach $lap ($c->find('overlapping',@box))   {
	if  (($lap ne $markid) && ($lap ne $lblid))  {
	    foreach $tag ($c->gettags($lap))  {
		unless ($tag =~ /^SeqLine/)   { $clash = 1; last LAPLOOP; }
	    }
	}
    }  

# If a clash is found, loop through moving the new annotation slightly farther
#   down, and exit the loop once it's been moved far enough down that it 
#   doesn't overlap any of the other annotations
    $loopnum = 0;
    while ($clash)  {
	$loopnum++;
	$c->move($markid, 0, 4);
	$c->move($lblid, 0, 4);
	$c->SequenceMakeRoom($lblid,$markid);
	$clash = 0;
#  Fixed bug of overlapping marks with previous labels -- 8/3/95
#	@box = $c->bbox($lblid);
	@box = $c->bbox($lblid,$markid);
	$box[3] += -2.5;       # correcting for Tcl/Perl bbox difference
	  # not sure if it's necessary here -- if this line is commented out,
	  #  it doesn't seem to make any difference
      LAPLOOP2:
	foreach $lap ($c->find('overlapping',@box))   {
	    if  (($lap ne $markid) && ($lap ne $lblid))  {
		foreach $tag ($c->gettags($lap))  {
		    unless ($tag =~ /^SeqLine/)   {$clash = 1; last LAPLOOP2;}
		}
	    }
	}
    }
    
    $c->lower($markid);
    $c->lower($lblid);
    $c->move('bars', 9999, 0);
    $c->lower('bars');
}
    

sub SequenceAnnotate  {
    my $c = shift;
    my $from = shift;
    my @args = @_;
    my $SeqWidth = $c->{SeqWidth};
    my $SeqLineSpace = $c->{SeqLineSpace};
    my $SeqFontWidth = $c->{SeqFontWidth};
    my $SeqFontHeight = $c->{SeqFontHeight};
    my $SeqStart = $c->{SeqStart};
    my($arrow, $tagtag, @fromxy, $x0, $y0, @toxy, $at, $dots, $x1, $y1, $temp,
       $to, $length, $color, $type, $offset, $label);

    #  Set some defaults
    $to = $from;
    $length = 1;
    $color = 'red';		
    $type = 'none';
    $offset = 'absolute';
    $label = "";
    $arrow = 'none';
    
    my @OptionNames = ('to', 'arrow', 'length', 'color', 'label', 'offset');
    eval &bioTk_ParseArgs($c, \@args, \@OptionNames);
		     
####  Error Checking
    # skipped unrecognized option error
    # skipped "name-of-variable" check for -to
    if (defined($arrow)) {
        if    ($arrow eq 'left')   { $type = 'first'; }
	elsif ($arrow eq 'right')  { $type = 'last'; }
	elsif ($arrow eq 'both')   { $type = 'both'; }
	elsif ($arrow eq 'none')   { $type = 'none'; }
	else  { print "bioTk_Sequence->SequenceAnnotate: ",
		"incorrect arrow type $arrow\n";  return 0; }
    }
    if (defined($to) && !($to =~ /^-?[0-9]+$/))  {
	print "bioTk_Sequence->SequenceAnnotate: ",
	"to takes either an integer or variable name\n";
	return 0;
    }
    if ($length =~ /^[0-9]+$/)  { $to += $length-1; }
    else  {
	print "bioTk_Sequence->SequenceAnnotate: ",
	"length must be a positive integer\n";
	return 0;	
    }

    if ($offset eq 'absolute')     { if (($from<0) && ($to>0)) { $to--; }  }
    elsif ($offset eq 'relative')  { $from += $SeqStart;  $to += $SeqStart; }
    elsif (defined($offset)) {
	print "bioTk_Sequence->SequenceAnnotate: ",
	"incorrect offset type\n";
	return 0;
    }
####

    $from = int($from); $to = int($to);   # just in case, force these to ints
    if (($from<0) && ($to>0))   { $to++; }
    if (($from!=0) && ($to!=0) && (($c->SequenceLocation($from))[0] != 0) &&
 	                          (($c->SequenceLocation($to))[0] != 0) )   {
	$tagtag = $label;
	$tagtag =~ s/ /\_/g;   # change 'The Label' to 'The_Label'
	if ($tagtag eq "")   { $tagtag = 'annotation'; }
	$tagtag .= "_$from"."_$to";
	if ($from>$to)  { $temp=$from; $from=$to; $to=$temp; } 
	@fromxy = $c->SequenceLocation($from);

	$x0 = $fromxy[0];
	$y0 = $fromxy[1];
	@toxy = $c->SequenceLocation($to);
	$at = (int(bioTk_TclDiv($from,$SeqWidth))) * $SeqWidth + 1;
	if ($at<0) {$at--;}
	$dots = "";
	while ($y0 < $toxy[1])  {
	    $x1 = 59 + $SeqWidth * $SeqFontWidth -2;
	    $y1 = $y0 + 1;
	    $c->SequenceDrawAnnotation($x0, $x1, $y1+2, $color, 
				       $dots.$label.'...', $tagtag, $type);
	    @toxy = $c->SequenceLocation($to);
	    $at += $SeqWidth;
	    if ($at == 0)   { $at++; }
	    @fromxy = $c->SequenceLocation($at);
	    ($x0,$y0) = @fromxy;
	    if ($dots eq "")  { $dots = '...'; }
	}
	
	$x1 = $toxy[0] + $SeqFontWidth - 2;
	$y1 = $toxy[1] + 1;

	$c->SequenceDrawAnnotation($x0, $x1, $y1+2, $color, $dots.$label,
				   $tagtag, $type);
	$c->move('bars', -9999, 0);
	$c->configure('-scrollregion' => [ 0, 0, 
		      ($SeqWidth * $SeqFontWidth + 70), 
		      (($c->bbox($c->find('overlapping',0,0,9999,99999)))[3] +
		       $SeqFontHeight * $SeqLineSpace)  ]    );
	$c->move('bars', 9999, 0);
	return $tagtag;
    }
    else   { return ""; }
}	    


sub SequenceHighlight  {
    my $c = shift;
    my $position = shift;
    my @args = @_;
    my $SeqWidth = $c->{SeqWidth};
    my $SeqFontWidth = $c->{SeqFontWidth};
    my $SeqFontHeight = $c->{SeqFontHeight};
    my $SeqStart = $c->{SeqStart};
    my $color = $DefaultSeqHighlightColor;
    
    my $preserve = 0;
    my $length = 1;
    my $to = $position;
    my $offset = 'absolute';
    my($temp, $mid, @fromxy, $x0, $y0, @midxy, $x1, $y1, $markid, @toxy);
    my $none;  # undefined variable for preventing outlines
    my @OptionNames = ('to', 'length', 'color', 'preserve', 'offset');
    eval &bioTk_ParseArgs($c, \@args, \@OptionNames);

####  Error Checking
    #    skipped the global $to stuff from Tcl version
    #    skipped the $c existence check
    unless ($to =~ /^-?[0-9]+$/)  {
	print "invalid span\n"; return 0;  }
    unless ($length =~ /^[0-9]+$/)  {
	print "length must be a positive integer\n"; return 0; }
    if ($offset eq 'relative')  {
	$position += $SeqStart;
	$to += $SeqStart;
    }
    elsif ($offset eq 'absolute')  { }
    elsif (defined($offset))  { 
	print "incorrect offset type $offset\n";  return 0; }
####


    if (($position<0) && ($to>=0))  { $to++; }
  # Remember, SequenceLocation returns array -- so have to subscript in...
  #    because treating array like a scalar uses last element of array in Perl,
  #    but using array like a scalar in Tcl uses the array string
    if (($position!=0) && ($to!=0) &&
	   (($c->SequenceLocation($position))[0] != 0)  &&
	   (($c->SequenceLocation($to))[0] != 0)  )     {
	if (!$preserve)   { $c->delete('SeqHighlight'); }
	if ($position>$to)  {$temp = $position; $position = $to; $to = $temp;}
	$mid = ((int(bioTk_TclDiv($position-1,$SeqWidth)))+ 1) * $SeqWidth;
	while ($to>$mid)  {
	    @fromxy = $c->SequenceLocation($position);
	    $x0 = $fromxy[0];  $y0 = $fromxy[1] + 1;
	    @midxy = $c->SequenceLocation( ($mid<=0?($mid-1):$mid) );
	    $x1 = $midxy[0] + $SeqFontWidth;
	    $y1 = $y0 - $SeqFontHeight;
	    $markid = $c->create('rectangle', $x0, $y0, $x1, $y1,
				 '-fill' => $color, '-outline' => $none,
				 '-tags' => 'SeqHighlight' );
	    $c->lower($markid);
	    $c->raise($markid, 'bars');
	    $position = $mid + 1;
	    $mid += $SeqWidth;
	    if ($position<0)  { $position--; }
	}
	
	@fromxy = $c->SequenceLocation($position);
	$x0 = $fromxy[0]; $y0 = $fromxy[1] + 1;
	@toxy = $c->SequenceLocation($to);
	$x1 = $toxy[0] + $SeqFontWidth;
	$y1 = $toxy[1] - $SeqFontHeight;
	$markid = $c->create('rectangle', $x0, $y0, $x1, $y1,
			     '-fill' => $color, '-outline' => $none,
			     '-tags' => 'SeqHighlight' );
	$c->lower($markid);
	$c->raise($markid, 'bars');
    }
}


sub GetSequence {
    my $c = shift;
    my @args = @_;
    my @OptionNames = ('from', 'to', 'length', 'offset');
    my ($from, $to, $length, $offset, $tmp);
    my $Sequence = $c->{Sequence};
    my $SeqStart = $c->{SeqStart};
    $offset = 'absolute';
    eval &bioTk_ParseArgs($c, \@args, \@OptionNames);
####  Error Checking
    if (defined($from) && !($from =~ /^-?[0-9]+$/))  {
	print "invalid span\n"; return 0; }
    if (defined($to) && !($to =~ /^-?[0-9]+$/))  {
	print "invalid span\n"; return 0; }
    if (defined($length) && !($length =~ /^[0-9]+$/))  {
	print "length must be a positive integer\n"; return 0; }
####
    if ($offset eq 'relative')  {
	if (!(defined($from)))   { $from = 0; }  else  { $from--; }
	if (!(defined($to)))  {
	    if (defined($length))  { $to = $from + $length - 1; }
	    else { $to = 9999999; }
	}
	else  { 
	    $to--;
	    if ($from>$to)  { $tmp=$from; $from=$to; $to=$tmp; }
	}
    }
    elsif ($offset eq 'absolute')  {
	if (!(defined($from)))   { $from = 0; }
	else {
	    if ($from>0)  { $from--; }
	    $from = $from - $SeqStart;
	}
	if (!(defined($to)))  {
	    if (defined($length))   { $to = $from + $length - 1; }
	    else  { $to = 9999999; }
	}
	else  {
	    if ($to>0)  { $to--; }
	    $to =  $to - $SeqStart;
	    if ($from>$to)   { $tmp=$from; $from=$to; $to=$tmp; }
	}
    }
    else  { print "Error in GetSequence\n"; exit; }

    return substr($Sequence, $from, ($to-$from+1));
}



1;			      


