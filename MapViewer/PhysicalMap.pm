package PhysicalMap;

use strict;

use Bio::SeqIO;

use FeatureDataSource;
use CompAnalResult;

sub new {
    my $class= shift;
    my $datasource=shift;
    my $self = {};
    
    $self->{datasource}=$datasource;
    $self->{companalresults}=[];

    bless $self,$class;

    return $self;

}

sub get_bounds {
    my $self=shift;

    return $self->{datasource}->get_bounds();
}


sub get_organism {
    my $self=shift;
    return $self->{datasource}->get_organism();
}


sub get_chromosome {
    my $self=shift;
    return $self->{datasource}->get_chromosome();
}

sub get_seqobj {
    my $self=shift;
    
    return $self->{datasource}->get_seqobj();
}

sub extract_features {
    my $self=shift;
    my $start=shift;
    my $end=shift;
    my $minsize=shift;

    return $self->{datasource}->extract_features($start,$end,*minsize);
}


sub extract_companal_results {
    my $self=shift;
    my $start=shift;
    my $end=shift;
    my @companalreslist;

    foreach my $companalres (@{$self->{companalresults}}){
	my ($loc_start,$loc_end)=$companalres->bounds();
	if ($loc_start>=$start && $loc_start<=$end) {
	    push @companalreslist,$companalres;
	} else {
	    if ($loc_end>=$start && $loc_end<=$end) {
		push @companalreslist,$companalres;
	    }
	    else {
		if ($loc_start<=$start && $loc_end>=$end) {
		    push @companalreslist,$companalres;
		}
	    }
	}
    }
    return @companalreslist;
}

sub load_features {
    my $self=shift;
    my $filename=shift;
    my $format=shift;

    my $in=new Bio::SeqIO('-file'=>"$filename",'-format'=>"$format");

    $self->{features}=[];
    $self->{portions}=();
    while (my $seq = $in->next_seq) {
	$self->{seqobj}=$seq;
	push @{$self->{features}},$seq->all_SeqFeatures;
    } 

    my $index=0;
    foreach my $feature (@{$self->{features}}) {
	$self->{featurenames}->{$feature->primary_tag}++;
	if ($feature->primary_tag eq 'source') {
	    my ($source,@dummy)=$feature->each_tag_value('organism');
	    $self->{organism}=$source;
	    if ($feature->has_tag('chromosome')) {
		my ($chromosome,@dummy)=$feature->each_tag_value('chromosome');
		$self->{chromosome}=$chromosome;
	    }
	}
	my $loc_start=$feature->start;
	my $loc_end=$feature->end;
	my $portion_start=int($loc_start/$PhysicalMap::PORTION_SIZE);
	my $portion_end=int($loc_end/$PhysicalMap::PORTION_SIZE);
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

sub get_feature_location {
    my $self=shift;
    my $qualifier=lc shift;
    my $qvalue=lc shift;

    return $self->{datasource}->get_feature_location($qualifier,$qvalue);
}

sub load_companal_results {
    my $self=shift;
    my $filename=shift;

    my $restab=CompAnalResultFactory::load_results_from_file($filename);

    foreach my $companalres (@$restab) {
	my $type=$companalres->type;
	my ($start,$end)=$companalres->bounds;
	my $replace_index=-1;
	for (my $i=0;$i<=$#{$self->{companalresults}};$i++) {
	    $replace_index=$i
		if ($self->{companalresults}->[$i]->type eq $type);
	}
	if ($replace_index>=0) {
	    $self->{companalresults}->[$replace_index]=$companalres;
	} else {
	    push @{$self->{companalresults}},$companalres;
	}
    }
}

sub get_companal_result_types {
    my   $self=shift;
    my @res=();

    foreach my $companalresult (@{$self->{companalresults}}) {
	push @res,$companalresult->type;
    }

    return @res;
}

sub remove_companal_result_type {
    my $self=shift;
    my $type=shift;
    my @newres=();

    foreach my $companalresult (@{$self->{companalresults}}) {
	push @newres,$companalresult
	    if ($companalresult->type ne $type);
    }
    $self->{companalresults}=\@newres;
}

1
