package CompAnalResult::RHOMResult; 

use strict;

@CompAnalResult::RHOMResult::ISA=qw(CompAnalResult);


BEGIN {
    $CompAnalResultFactory::Factory{RHOM}=sub { return new CompAnalResult::RHOMResult };
}

sub new {
    my $class=shift;
    my $self=new CompAnalResult('RHOM');;

    bless $self,$class;

    $self->{states}=[];
    $self->{currentstate}=undef;

  
    return $self;
}

sub display {
    my $self=shift;
    print "Type = $self->{type}\n";
    print "Bounds = ($self->{start},$self->{end})\n";
    foreach my $state (@{$self->{states}}) {
	print "Id = $state->{id}\n";
	print "Color = $state->{color}\n";
	print "Smoothing = $state->{smoothing}\n";
	print "Start = $state->{start}\n";
	my $end=$state->{start}+$#{$state->{data}};
	print "End = $end\n";

    }
}

sub _start_tagged_data {
    my $self=shift;
    my $tag=shift;
    my $attributes=shift;

    if (lc $tag eq 'state') {
	my $id=$attributes->{'id'};
	$id='unknown'
	    if (!defined $id);
	my $color=$attributes->{'color'};
	$color='black'
	    if (!defined $color);
	my $smoothing=$attributes->{'smoothing'};
	$smoothing=0.05
	    if (!defined $smoothing);
	my $start=$attributes->{'start'};
	$start=1
	    if (!defined $start);
	$self->{currentstate}={id=>$id,
			       color=>$color,
			       smoothing=>$smoothing,
			       start=>$start,
			       data=>[]};
    }

}

sub _end_tagged_data {
    my $self=shift;
    my $tag=shift;

    if (lc $tag eq 'state' && $self->{currentstate}) {
	$self->{start}=$self->{currentstate}->{start}
	if ($self->{currentstate}->{start}<$self->{start});
	my $end=$self->{currentstate}->{start}+$#{$self->{currentstate}->{data}};
	$self->{end}=$end
	    if ($end>$self->{end});
	push @{$self->{states}},$self->{currentstate};	
	$self->{currentstate}=undef;
    }
}


sub _add_line {
    my $self=shift;
    my $value=shift;

    push @{$self->{currentstate}->{data}},$value
	if (defined $self->{currentstate});
}

1
