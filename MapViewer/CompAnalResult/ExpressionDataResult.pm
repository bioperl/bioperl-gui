package  CompAnalResult::ExpressionDataResult;

use strict;

@CompAnalResult::ExpressionDataResult::ISA=qw(CompAnalResult);

BEGIN {
    $CompAnalResultFactory::Factory{EXPRESSIONDATA}=sub { return new CompAnalResult::ExpressionDataResult };
}
sub new {
    my $class=shift;
    my $self=new CompAnalResult('EXPRESSIONDATA');

    bless $self,$class;

    $self->{start}=1e38;
    $self->{end}=-1;
    $self->{genes}=[];

    return $self;
}


sub _start_tagged_data {
    my $self=shift;
    my $tagname=shift;
    my $attributes=shift;

    if (lc $tagname eq 'gene') {
	$self->{currentgene}=$attributes->{'name'};
    }

    if (lc $tagname eq 'fragment') {
	my $start=$attributes->{'start'};
	my $end=$attributes->{'end'};
	($start,$end)=($end,$start)
	    if ($start>$end);
	my $wt_growth=$attributes->{'wt_growth'};
	$wt_growth=0
	    if (!defined $wt_growth);
	my $mutant_growth=$attributes->{'mutant_growth'};
	$mutant_growth=0
	    if (!defined $mutant_growth);
	my $betagal_exp=$attributes->{'betagal_exp'};
	$betagal_exp=0
	    if (!defined $betagal_exp);
	$self->{start}=$start
	    if ($start<$self->{start});
	$self->{end}=$end
	    if ($end>$self->{end});
	    push @{$self->{genes}},{gene=>$self->{currentgene},
				    start=>$start,end=>$end,
				    wt_growth=>$wt_growth,
				    mutant_growth=>$mutant_growth,
				    betagal=>$betagal_exp};
    }

}

1
