############################################################################
#  bioTkperl v0.8
#  Berkeley Drosophila Genome Project
#  Contact gregg@fruitfly.berkeley.edu
#
# Copyright (c) 1995 by Gregg Helt
# This software is provided "as is" without express or implied warranty of
# any kind, nor with representations about its suitability for any purpose.
#
############################################################################
#  bioTk_Utilities.pm
#  a few utilities used by bioTkperl widgets
#    
# bioTk_ParseArgs -- subroutine for parsing arguments to Tk widgets, 
#      based somewhat on bioTk_Arguments, and probably GetOpt::Long as well
#      eval the result to set (non-instance) variables (object instance
#      variables are automatically set without need for eval)
#
# bioTk_TclDiv -- subroutine to emulate Tcl's weird "/" operand rules
#   Usage:   bioTk_TclDiv($top,$bottom)
#         returns $top/$bottom, where "/" acts like Tcl's "/" operand
###########################################################################

package Bio::Tk::bioTk_Utilities;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(bioTk_TclDiv bioTk_ParseArgs);

sub bioTk_TclDiv  {
    #  bioTk_TclDiv emulates Tcl's weird "/" operand rules
    # _NOT_ a widget method, but a subroutine
    #  Assumes at the moment that the two arguments are both numeric

    #  If either has a decimal point, then just return the exact division
    if (($_[0] =~ /\./) || ($_[1] =~ /\./))   { return $_[0]/$_[1] ; }

    #  Otherwise, what to return depends on whether the exact division is
    #   positive or negative
    my $ExactDivision = $_[0]/$_[1];
    #  If positive, just return integer truncation
    if ($ExactDivision >= 0)   { return int($ExactDivision); }
    else  { 
       # If negative and there's a remainder, return integer truncated _down_
	if ($_[0] % $_[1])  { return int($ExactDivision)-1; }
       # If negative and no remainder, return integer truncation
	else  { return int($ExactDivision); }
    }
}

sub bioTk_ParseArgs  {
    #  Usage: [eval] &bioTk_ParseArgs($widget, \@Arglist, \@OptionNames,
    #                                               [ \%InstanceVars ] );
    #
    # In this version, @ArgList is parsed according to @OptionNames _and_
    # %InstanceVars, such that:
    #   1. for each option/value pair in @ArgList that matches with an
    #       option in @OptionNames, a line is added to the returned $evalstring
    #       that follows the form "$option = value"
    #   2. for each option/value pair that matches with an option/InstanceVar 
    #       pair in %InstanceVars, that InstanceVar is set in the $widget
    #       object to $value, e.g.  $c->{InstanceVar} = $value;
    # The returned value is a string which can be evaled to set the 
    #    determined "$option = value" variables (this needs to be evaled 
    #    upon return (rather than happening automatically) in order to 
    #    avoid variable scope problems (particularly with 'my'))
    # The $widget instance variables, on the other hand, are automatically
    #    set with bioTk_ParseArgs (as a side effect -- no evaling needed)
    # %InstanceVars is optional -- if left out, no instance variables of 
    #     the $widget object will be set
    # Unlike the previous bioTk_ParseArgs, there is no error subroutine
    #    ref passed in (at least at the moment)
    #  
    # Example:    
    #   
    #    @ArgList = ('-op1'=> 1, '-op2'=> 2, '-op3' => 3);
    #    @OptionNames = ('op1', 'op2', 'op3');
    #    %InstanceVars = ('op2' => 'varA', 'op3' => 'varB');
    #    $evalstring = &bioTk_ParseArgs($widget, \@Arglist, 
    #                                         \@OptionNames,\%InstanceVars);
    #    eval $evalstring;
    #  Now the following variables have been set:
    #      $op1 = 1, $op2 = 2, $op3 = 3,
    #      $widget->{varA} = 2,  $widget->{varB} = 3
    #    
    # Modified 5/7/95, G.H.
    # Modified 8/16/95 G.H. -- changed to returning string of assignments 
    #                          of @_ -- this makes it easy to deal with refs

    my $widget = $_[0];
    my ($option,$value,$name, @values);
    my (@arglist, %validoption, %ivars);
    my $evalstring = "";
    @arglist = @{$_[1]};
    foreach $name (@{$_[2]})  { $validoption{$name} = 1; }
    if ($#_ == 3)  { %ivars = %{$_[3]}; }
 ### Get next argument ####
    for ($i = 0; $i <= $#arglist; $i++)  {
	$option = $arglist[$i];
	unless ($option =~ s/^\-//)   {
	    print STDERR "Format error: ",
	                 "option \'$option\' does not begin with \'-\'\n";
	    $i++; next;
	}
	unless  ($validoption{$option})  {
	    print STDERR ("Unknown option: ", $option, "\n");
	    $i++; next;
	}

	$evalstring .= '$'.$option.' = $_['.(++$i).']; ' ;
	$value = $arglist[$i];
        if ($ivars{$option})    { $widget->{$ivars{$option}} = $value; }
   }
   $evalstring .= "\n";
#   print $evalstring;
   return $evalstring;
}

1;







