#
#  bioTk_SeqSubs
#
#  Extra bits ported from bioTk1.2 tcl code
#  These are the procedures that are independent of a sequence widget/canvas
#

use Bio::Tk::bioTk_Utilities;

#########################################################################
# RANDOM SEQUENCE GENERATOR
#

sub bioTk_RandomSequence  {
    my $length = shift;
    my @args = @_;
    my $seed = 0;
    my @alphabet = ('a', 'c', 'g', 't');
    my @frequencies = (25,25,25,25);
    my $fast = 1;
    my ($seq, $i);
    # BUG in sequence.tcl -- $fast is always set to 1???
    #   so always use fast method, which doesn't even factor in the 
    #   base frequencies
    # Although I've tested both sequence.tcl and bioTk_SeqSubs with $fast = 0, 
    #   and they both work that way too (at least for 100 bp)
    @OptionNames = ('seed', 'alphabet', 'frequencies');
    eval &bioTk_ParseArgs(\&bioTk_RandomSequence, \@args, \@OptionNames);
    #  skipping error-checking for now
    if ($fast)  {
	for ($i=0; $i<$length; $i++)  {
#	    print $seed, "\n";
	    $seed = 457*($seed+4321)%1234567;
	    $seq .= $alphabet[$seed%4];
	}
    }
    else {
	my(@ts, $next, $j, $flen, $tot, $f);
	$flen = $#frequencies;
        $tot = 0;
	foreach $f (@frequencies)   { $tot += $f; }
	$i = 0;
	foreach $f (@frequencies)  {
	    $i += int(($f/$tot)*1234567);
	    push @ts, $i;
	}
	for ($i=0; $i<$length; $i++)  {
	    $seed = 457*($seed+123)%1234567;
	    $next = $alphabet[$flen];
	    for ($j=0; $j<$flen; $j++)  {
		if ($seed<$ts[$j])  { $next = $alphabet[$j]; last; }
	    }
	    $seq .= $next;
	}
    }
    return $seq;
}


#########################################################################
# AUDIO BASE READING
# 

sub bioTk_SayBase  {
    my $base = shift;
    my @args = @_;
    my $program = "$ENV{'BIOTKPERL_LIBRARY'}/audio/play";
    my $voice = 'male';
    my $audio_dir = "$ENV{'BIOTKPERL_LIBRARY'}/audio";
    eval &bioTk_ParseArgs(\&bioTk_SayBase, \@args, ['voice', 'program']);
#    print "$voice $program\n";
    `$program -v 10 $audio_dir/$base.$voice.au`;
}


sub bioTk_SaySequence  {
    my $sequence = shift;
    my @args = @_;
    my $program = "$ENV{'BIOTKPERL_LIBRARY'}/audio/play";
    my $audio_dir = "$ENV{'BIOTKPERL_LIBRARY'}/audio";
    my $rate = 100;
    my $voice = 'male';
    my $pause = 0;
    my $volume = 20;
    my $base;
    
    my @OptionNames = ('voice', 'program', 'rate', 'pause', 
		       'interaction', 'volume');
    eval &bioTk_ParseArgs(\&bioTk_SaySequence, \@args, \@OptionNames);
    my $interval = int(60000.0/$rate) - 550;
#    print "rate -- $rate, interval -- $interval, volume -- $volume\n";
#    $interval = $interval/1000;     # using Perl's sleep instead of 
                                    # Tcl's after -- sleep units are seconds,
                                    # after units are milliseconds
#    print "interval -- $interval\n";
    if ($interval<0)  {$interval=0;}
    my $i = 0;
    while ($i < length($sequence))  {
	#  put in pause option stuff here
	Tk::after($interval);
#	sleep $interval;
	$base = substr($sequence,$i,1);
	`$program -v $volume $audio_dir/$base.$voice.au`;
	$i++;
    }
}


1;

