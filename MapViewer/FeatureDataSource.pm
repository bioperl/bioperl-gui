package FeatureDataSource;

use strict;

use Bio::Seq;

my $PORTION_SIZE=100000;

sub _new {
    my $class=shift;

    my $self={};

    $self->{features}=[];
    $self->{featurenames}={};
    $self->{start}=-1;
    $self->{end}=-1;
    $self->{organism}='Unknown';
    $self->{chromosome}='N/A';

    bless $self,$class;

    return $self;
    
    
}

sub _load_features {
    my $self=shift;
    my $seqobj=shift;

    $self->{features}=[];
    $self->{portions}=();
    $self->{seqobj}=$seqobj;
    push @{$self->{features}},$seqobj->all_SeqFeatures;

    my $index=0;
    foreach my $feature (@{$self->{features}}) {
	$self->{featurenames}->{$feature->primary_tag}++;
	if ($feature->primary_tag eq 'source') {
	    if ($feature->has_tag('organism')) {
		my ($source,@dummy)=$feature->each_tag_value('organism');
		$self->{organism}=$source;
	    }
	    if ($feature->has_tag('chromosome')) {
		my ($chromosome,@dummy)=$feature->each_tag_value('chromosome');
		$self->{chromosome}=$chromosome;
	    }
	}
	my $loc_start=$feature->start;
	my $loc_end=$feature->end;
	my $portion_start=int($loc_start/$PORTION_SIZE);
	my $portion_end=int($loc_end/$PORTION_SIZE);
	push @{$self->{portions}->[$portion_start]},$index;
	for (my $portion=$portion_start+1;$portion<=$portion_end;$portion++) {
	    push @{$self->{portions}->[$portion]},$index;
	}
	if ($self->{start}==-1 || $loc_start<$self->{start}) {
	    $self->{start}=$loc_start;
	}
	if ($self->{end}==-1 || $loc_end>$self->{end}) {
	    $self->{end}=$loc_end;
	}
	$index++;
    }    
}

sub get_bounds {
    my $self=shift;

    return ($self->{start},$self->{end});
}

sub get_organism {
    my $self=shift;

    return $self->{organism};
}

sub get_chromosome {
    my $self=shift;

    return $self->{chromosome};
}

sub get_seqobj {
    my $self=shift;

    return $self->{seqobj};
}

sub extract_features {
    my $self=shift;
    my $start=shift;
    my $end=shift;
    my $minsize=shift;

    $minsize=1
	if (!defined $minsize);

    my @featurelist;

    my $featuretab=$self->{features};
    my $start_portion=int($start/$PORTION_SIZE);
    my $end_portion=int($end/$PORTION_SIZE);
    my %displayed=();
    for (my $portion=$start_portion;$portion<=$end_portion;$portion++) {
	foreach my $index (@{$self->{portions}->[$portion]}) {
	    if (!$displayed{$index}) {
		my $feature=$featuretab->[$index];
		my $loc_start=$feature->start;
		my $loc_end=$feature->end;
		if (($loc_start>=$start && $loc_start<=$end) ||
		    ($loc_end>=$start && $loc_end<=$end) ||
		    ($loc_start<$start && $loc_end>$end)) {
		    push @featurelist,$featuretab->[$index];
		    $displayed{$index}=1;
		}
	    }
	}
    }
    return @featurelist;
}

sub get_feature_location {
    my $self=shift;
    my $qualifier=lc shift;
    my $qvalue=lc shift;

    my $start=-1;
    my $end=-1;
    my $found=0;
    for (my $i=0;$i<=$#{$self->{features}} && !$found;$i++) {
	my $feature=$self->{features}->[$i];
	if ($feature->has_tag($qualifier)) {
	    my (@values)=$feature->each_tag_value($qualifier);
	    foreach my $value (@values) {
		if (lc $value eq $qvalue) {
		    $found=1;
		    $start=$feature->start;
		    $end=$feature->end;
		}
	    }
	}
    }
    return ($start,$end);
}

1
