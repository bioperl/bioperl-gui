package CompAnalResult;

use strict;

use FindBin;

use lib $FindBin::Bin;


sub new {
    my $class=shift;
    my $type=shift;
    my $self= {};
    bless $self,$class;
    $self->{type}=$type;
    $self->{start}=1e10;
    $self->{end}=-1;
    return $self;
}

sub bounds {
    my $self=shift;
    return ($self->{start},$self->{end});
}

sub type {
    my $self=shift;
    return $self->{type};
}


sub _start_tagged_data {
}

sub _add_line {
}

sub _end_tagged_data {
}

package CompAnalResultHandler;

use strict;

sub new {
    my $class=shift;

    my $self={};

    $self->{in_companalresults}=0;
    $self->{currentinstance}=undef;
    $self->{currentcharacterline}='';
    $self->{companalresult_instances}=[];

    bless $self,$class;

    return $self;

}

sub start_element {
    my $self=shift;
    my $tag=shift;


    if (defined $self->{currentinstance}) {
	$self->{currentinstance}->_start_tagged_data($tag->{Name},$tag->{Attributes});
    }

    
    if ($self->{in_companalresults} && !defined $self->{currentinstance}) {
	$self->{currentinstance}=&{$CompAnalResultFactory::Factory{uc $tag->{Name}}};
    }
      
    if (lc $tag->{Name} eq 'companalresults') {
	$self->{in_companalresults}=1;
    }
}

sub end_element {
    my $self=shift;
    my $tag=shift;

    $self->{in_companalresults}=0
	if (lc $tag->{Name} eq 'companalresults');

    if (defined $self->{currentinstance}) {
	if (uc $tag->{Name} eq $self->{currentinstance}->type) {
	    push @{$self->{companalresult_instances}},$self->{currentinstance};
	    $self->{currentinstance}=undef;
	} else {
	    $self->{currentinstance}->_end_tagged_data($tag->{Name},
						       $tag->{Attributes});
	}
    }
}


sub characters {
    my $self=shift;
    my $contents=shift;
    my $data=$contents->{Data};

    $self->{currentcharacterline}.=$data;

    if ($self->{currentcharacterline} =~ /\n/) {
	my ($before,$after)=split('\n',$self->{currentcharacterline});
	$self->{currentinstance}->_add_line($before)
	    if (length($before) && defined $self->{currentinstance});
	$self->{currentcharacterline}=$after;
    }


}

sub get_comp_anal_results {
    my $self=shift;

    return $self->{companalresult_instances};

}

package CompAnalResultFactory;

use strict;

use XML::Parser::PerlSAX;

BEGIN {
    my $subdir=$FindBin::Bin;
    %CompAnalResultFactory::Factory=();
    my @modules=<$subdir/CompAnalResult/*.pm>;

    foreach my $module (@modules) {
	eval {
	    require $module;
	}
    }
}

sub load_results_from_file {
    my $filename=shift;
    local *COMPANALRESFILE;
    open(COMPANALRESFILE,"< $filename") || return [];
    my $handler=new CompAnalResultHandler;
    my $parser=new XML::Parser::PerlSAX(DocumentHandler => $handler);
    $parser->parse(*COMPANALRESFILE);
    close(COMPANALRESFILE);
    my $results=$handler->get_comp_anal_results;
    return $results;
}

1
