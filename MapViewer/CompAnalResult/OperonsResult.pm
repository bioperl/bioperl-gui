package CompAnalResult::OperonsResult;

use strict;

@CompAnalResult::OperonsResult::ISA=qw(CompAnalResult);

BEGIN {
    $CompAnalResultFactory::Factory{OPERONS}=sub { return new CompAnalResult::OperonsResult };
}

sub new {
    my $class=shift;
    my $self=new CompAnalResult('OPERONS');;

    bless $self,$class;

    $self->{start}=1e38;
    $self->{end}=-1;
    $self->{operons}=[];

    return $self;
}

sub _start_tagged_data {
    my $self=shift;
    my $tag=shift;
    my $attributes=shift;

    if (lc $tag eq 'operon') {
	my $start=$attributes->{'start'};
	my $end=$attributes->{'end'};
	my $strand=$attributes->{'strand'};
	$self->{start}=$start
	    if ($start<$self->{start});
	$self->{end}=$end
	    if ($end>$self->{end});
	push @{$self->{operons}},{start=>$start,end=>$end,strand=>$strand};
    }
}

1
