package PaintDevice::ReactivePaintDevice;

use strict;

@PaintDevice::ReactivePaintDevice::ISA=qw(PaintDevice);

sub _new {
    my $class=shift;
    my $self= _new PaintDevice;

    bless $self,$class;

    $self->{type}='reactive';
    $self->{r_zones}=[];
    $self->{enter_listeners}=[];
    $self->{move_listeners}=[];
    $self->{select_listeners}=[];
    return $self;

}

sub clear {
    my $self = shift;

    $self->PaintDevice::clear();
    $self->{r_zones}=[];
}

sub add_reactive_zone {
    my $self=shift;
    my $xmin=shift;
    my $ymin=shift;
    my $xmax=shift;
    my $ymax=shift;
    my $userdata=shift;

    my $r_zone={xmin=>$xmin, ymin=>$ymin, xmax=>$xmax, ymax=>$ymax,
	     userdata=>$userdata};

    push @{$self->{r_zones}},$r_zone;

}

sub clear_listeners {
    my $self=shift;

    $self->{enter_listeners}=[];
    $self->{move_listeners}=[];
    $self->{select_listeners}=[];
}

sub add_listener {
    my $self=shift;
    my $listener=shift;
    my $type=shift;

    
    push @{$self->{enter_listeners}},$listener
	if (!defined $type || $type eq 'ENTER');
    push @{$self->{move_listeners}},$listener
	if (!defined $type || $type eq 'MOVE');
    push @{$self->{select_listeners}},$listener
	if (!defined $type || $type eq 'SELECT');
}

1
