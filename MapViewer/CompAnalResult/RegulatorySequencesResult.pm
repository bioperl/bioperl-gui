package CompAnalResult::RegulatorySequencesResult;

use strict;

@CompAnalResult::RegulatorySequencesResult::ISA=qw(CompAnalResult);

BEGIN {
    $CompAnalResultFactory::Factory{REGULATORYSEQUENCES}=sub { return new CompAnalResult::RegulatorySequencesResult };
}

sub new {
    my $class=shift;
    my $self=new CompAnalResult('REGULATORYSEQUENCES');;

    bless $self,$class;

    $self->{start}=1e38;
    $self->{end}=-1;
    $self->{regseqs}=[];

    return $self;
}

sub _start_tagged_data {
    my $self=shift;
    my $tag=shift;
    my $attributes=shift;

    if (lc $tag eq 'motif') {
	    my $pos=$attributes->{'position'};
	    my $strand=$attributes->{'strand'};
	    my $pattern=$attributes->{'pattern'};
	    $self->{start}=$pos
		if ($pos<$self->{start});
	    $self->{end}=$pos
		if ($pos>$self->{end});
	    push @{$self->{regseqs}},{pos=>$pos,pattern=>$pattern,strand=>$strand};
	}
}


1
