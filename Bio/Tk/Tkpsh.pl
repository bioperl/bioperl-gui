#
#   tkpsh subs
#      -- Gregg Helt
#
#     A wish-like shell for Tkperl
#     Treats input from STDIN as an event (in the Tk event-handler loop)
#        and evals it.  Single line input is simply evaled. In the case of 
#        multi-line input, $command is appended to with each new line, then 
#        evaled. If the eval is successful, a new $command string is begun.  
#        If the eval is not successful, the $command string continues to grow.
#        So it is important to flush out $command strings with errors.
#     To see the current command string, use '_show'
#     To flush/delete an erroneous command string, use '_flush'


use Tk;
require 'flush.pl';

sub SetUpTkpsh {
    my $prompt = shift;
    unless ($prompt)  { $prompt = 'tkpsh< '; }
    Tk->fileevent(STDIN, 'readable', sub { &Tkpsh_Eval_Input($prompt); } );
    printflush(STDOUT, $prompt);
}

sub Tkpsh_Eval_Input  {
    my $prompt = shift;
    unless ($prompt)  { $prompt = 'tkpsh< '; }
    my $line = <STDIN>;
    if ($line eq "_show\n")  {
	if ($command eq '')  { print "No current input\n"; }
	else  { print $command; printflush(STDOUT, "\t"); return; }
    }
    elsif ($line eq "_flush\n")  { 
	$command = '';  print "Flushed input\n";
    }
    else  {
	$command .= $line;
	eval $command;
	if ($@)  { 
	#    print "$@\n"; 
	    printflush(STDOUT, "\t");  return;   } 
	else  { $command = '';  }  
    }
    printflush(STDOUT, $prompt); 
    return;
}

