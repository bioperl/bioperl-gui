package CompAnalResultWidget;

use CompAnalResult;


sub new {
    my $lcass=shift;
    my $layout=shift;

    my $self={};

    $self->{layout}=$layout;

    bless $self,$class;

    return $self;
}

sub type {
    my $self=shift;
    
    return $self->{companalresult}->{type};
}

sub layout {
    my $self=shift;
    return $self->{layout};
}

package CompAnalResultWidgetFactory;

use strict;

use FindBin;

use lib $FindBin::Bin;

BEGIN {

    my $subdir=$FindBin::Bin;
    %CompAnalResultWidgetFactory::Factory=();
    my @modules=<$subdir/CompAnalResultWidget/*.pm>;

    foreach my $module (@modules) {
	eval {
	    require $module;
	}
    }
}

sub get_widget_instance {
    my $companal_result= shift;
    my $type=uc $companal_result->type;


    return undef
	unless defined $CompAnalResultWidgetFactory::Factory{$type};

    return &{$CompAnalResultWidgetFactory::Factory{$type}}($companal_result);
}

1

