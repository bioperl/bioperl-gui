package PhysicalMapWidget;

=head1 NAME

    PhysicalMapWidget


=head1 SYNOPSIS

    use PhysicalMapWidget;

    $paintdevice=... # Somehow get a reference on a PaintDevice.
    $pmapwidget=new PhysicalMapWidget($paintdevice);

    $pmap=...        # Somehow get a reference on a PhysicalMap.
    ($begin,$end,$step)=(1,20000,5000) # Define the range of the
                                       # map to be displayed.

    # Add the map to the map widget.
    $mapid=$pmapwidget->append_map($pmap,$begin,$end,$step);

    # Redner the map.
    $pmapwidget->render();

=head1 DESCRIPTION

The PhysicalMapWidget module implements the routines necessary to
render portions of annotated genomic physical maps.

A single instance of a PhysicalMapWidget is capable of displaying
portions of multiple physical maps. In addition results of in silico
analyses can be superimposed on the physical maps.

If supported by the PaintDevice on which the map is rendered,
interaction with the displayed features is possible. 

=head1 METHODS

=over

=cut

use strict;

use Carp;

use PhysicalMap;

use PhysicalMapStripSet;

use FeatureWidget;
use CompAnalResultWidget;

$PhysicalMapWidget::sequence_display_threshold=100;

=item new()

Instantiates a new empty PhysicalMapWidget. When maps are added to this
widget, their rendering will take place on the paintdevice given as argument.

Usage: $widget=new PhysicalMapWidget($paintdevice);

Arguments: 

=over

=item $paintdevice : PaintDevice on which the maps will be rendered.

=back

Returns: the reference of a new PhysicalMapWidget.

=cut

sub new {
    croak 'usage: $widget=PhysicalMapWidget::new($paintdevice)'
	if (@_ != 2);

    my $class = shift;
    my $self = {};

    $self->{paintdevice}=shift;
    $self->{mapinfo}=[];
    $self->{mapcounter}=0;

    $self->{paintdevice}->color_alloc('grey95',0.95,0.95,0.95);
    $self->{paintdevice}->color_alloc('grey90',0.9,0.9,0.9);
    $self->{paintdevice}->color_alloc('grey85',0.85,0.85,0.85);
    $self->{paintdevice}->color_alloc('grey80',0.8,0.8,0.8);


    $self->{backgroundcolors}=[];
    push @{$self->{backgroundcolors}},'white';
    push @{$self->{backgroundcolors}},'grey95';
    push @{$self->{backgroundcolors}},'grey90';
    push @{$self->{backgroundcolors}},'grey85';
    push @{$self->{backgroundcolors}},'grey80';

    bless $self,$class;

    return $self;
}

=item get_paintdevice()

Returns the PaintDevice associated to this PhysicalMapWidget.

Usage: $paintdevice=$widget->get_paintdevice();

=back

=cut

sub get_paintdevice {
    my $self=shift;
    return $self->{paintdevice};
}

=item set_paintdevice()

Changes the PaintDevice associated to this PhysicalMapWidget.

Usage: $widget->set_paintdevice($paintdevice);

Arguments:

=over

=item $paintdevice : the new PaintDevice on which the maps will be rendered.

=back

=cut

sub set_paintdevice {
    my $self=shift;
    my $paintdevice=shift;
    $self->{paintdevice}=$paintdevice;
}

=item append_map()

Appends a genomic map to the set of maps to be displayed. 

Usage: $mapid=$widget->append_map($map,$begin,$end,$step);

Arguments:

=over

=item $map: a reference of a PhysicalMap object,

=item $begin: the first  base of the displayed map portion,

=item $end: the last base of the displayed map portion,

=item $step: the number of bases per displayed line.

=back

Returns: an identifier for the newly added map.

=cut

sub append_map {
    croak 'usage: $mapid=$widget->append_map($map,$begin,$end,$step)'
	if (@_ != 5);

    my $self=shift;
    my ($map,$begin,$end,$step)=@_;

    my $mapinfo={};

    $mapinfo->{map}=$map;
    $mapinfo->{begin}=$begin;
    $mapinfo->{end}=$end;
    $mapinfo->{step}=$step;
    $mapinfo->{minfeaturesize}=1;
    $mapinfo->{mapid}=++$self->{mapcounter};

    push @{$self->{mapinfo}},$mapinfo;

    return $mapinfo->{mapid};

}

=item insert_map()

Appends a genomic map to the set of maps to be displayed. 

Usage: $newmapid=$widget->insert_map($newmap,$begin,$end,$step,$oldmapid,$where);

Arguments:

=over

=item $newmap: a reference of a PhysicalMap object,

=item $begin: the first  base of the displayed map portion,

=item $end: the last base of the displayed map portion,

=item $step: the number of bases per displayed line.

=item $oldmapid: the id of an existing physical map used to position the new map.

=item $where: character string, either 'before' or 'after', specifies the location of the new map relative to the map referenced by $oldmapid.

=back

Returns: an identifier for the newly added map.

=cut

sub insert_map {
    croak 'usage: $newmapid=$widget->append_map($newmap,$begin,$end,$step,$oldmapid,$where)'
	if (@_ != 7);

    my $self=shift;
    my ($newmap,$begin,$end,$step,$oldmapid,$where)=@_;

    $where=lc $where;
    if ($where ne 'before' && $where ne 'after') {
	carp "PhysicalMapWidget::insert_map(): unknown insertion position, using 'berfore";
	$where='before';
    }

    my $mapindex=$self->_mapindex_lookup($oldmapid);
    if ($mapindex<0) {
	carp "PhysicalMapWidget::insert_map(): invalid map identifier: $oldmapid";
	return;
    }
	    
    

    my $mapinfo={};

    $mapinfo->{map}=$newmap;
    $mapinfo->{begin}=$begin;
    $mapinfo->{end}=$end;
    $mapinfo->{step}=$step;
    $mapinfo->{minfeaturesize}=1;
    $mapinfo->{mapid}=++$self->{mapcounter};

    $mapindex++
	if ($where eq 'after');

    splice @{$self->{mapinfo}},$mapindex,0,$mapinfo;

    return $mapinfo->{mapid};

}

=item remove_map()

Removes a map from the set of maps managed by this PhysicalMapWidget.

Usage: $widget->remove_map($mapid);

Arguments:

=over

=item $mapid: identifier for the map to be removed.

=back

=cut

sub remove_map {
    croak 'usage: $widget->remove_map($mapid)'
	if (@_ != 2);

    my $self=shift;
    my $mapid=shift;

    my $mapindex=$self->_mapindex_lookup($mapid);
    if ($mapindex<0) {
	carp "PhysicalMapWidget::remove_map(): invalid map identifier: $mapid";
	return;
    }

    splice @{$self->{mapinfo}},$mapindex,1;
}


=item set_view_range()

Defines the portion of a map to be displayed.

Usage: $widget->set_view_range($mapid,$begin,$end,$step);

Arguments:

=over

=item $mapid: identfier of the map for which the display parameters must be sset.

=item $begin: the first  base of the displayed map portion,

=item $end: the last base of the displayed map portion,

=item $step: the number of bases per displayed line.

=back

=cut

sub set_view_range {
    croak 'usage: $widget->set_view_range($mapid,$begin,$end,$step);'
	if (@_ != 5);

    my $self=shift;
    my ($mapid,$begin,$end,$step)=@_;

    my $mapinfo=$self->_mapinfo_lookup($mapid);
    if (! defined $mapinfo) {
	carp 'PhysicalMapWidget::set_view_range: invalid $mapid';
	return;
    }

    $mapinfo->{begin}=$begin;
    $mapinfo->{end}=$end;
    $mapinfo->{step}=$step;

}


=item get_view_range()

Returns the currently displayed portion of a map.

Usage: ($begin,$end,$step)=$widget->get_view_range($mapid);

Arguments:

=over

=item $mapid: identfier of the map for which the display parameters must be set.

=back

Returns: a list composed of three elements:

=over

=item $begin: the first  base of the displayed map portion,

=item $end: the last base of the displayed map portion,

=item $step: the number of bases per displayed line.

=back

=cut

sub get_view_range {
    croak 'usage: ($begin,$end,$step)=$widget->get_view_range($mapid);'
	if (@_ != 2);

    my $self=shift;
    my $mapid=shift;

    my $mapinfo=$self->_mapinfo_lookup($mapid);
    if (!defined $mapinfo) {
	carp 'PhysicalMapWidget::get_view_range: invalid $mapid';
	return;
    }

    my ($begin,$end,$step)=($mapinfo->{begin},$mapinfo->{end},$mapinfo->{step});
    return ($begin,$end,$step);
}

=item set_text_display_threshold()

Defines the minimum size of the features whose names are to be displayed.

Usage: $widget->set_text_display_threshold($value);

Arguments:

=over

=item $value a percentage giving the ratio of the feature size on the total line length above which feature names are displayed (values close to 0 will lead to the display of all feature names, and values close to 1 will lead to hide most of the feature names).

=back

=cut

sub set_text_display_threshold {
    croak 'usage: $widget->set_text_display_threshold($thresh);'
	if (@_ != 2);

    my $self=shift;
    my $value=shift;

    $ScalableFeatureWidget::display_threshold=$value;

}

=item get_text_display_threshold()

Returns the minimum size of the features whose names are to displayed.

Usage: $value=$widget->get_text_display_threshold();

Returns: a percentage giving the ratio of the feature size on the total line length above which feature names are displayed (values close to 0 will lead to the display of all feature names, and values close to 1 will lead to hide most of the feature names).

=cut

sub get_text_display_threshold {
    croak 'usage: $value=$widget->get_text_display_threshold();'
	if (@_ != 1);

    my $self=shift;

    return $ScalableFeatureWidget::display_threshold;

}

=item set_minimum_feature_size()

Defines the minimum size of the features to be displayed.

Usage: $widget->set_minimum_feature_size($mapid,$value);

Arguments:

=over

=item $mapid: identfier of the map for which the feature display size must be set.
=item $value: the minimum size (in base pairs) for features to be displayed.

=back

=cut

sub set_minimim_feature_size {
    croak 'usage: $widget->set_minimim_feature_size($mapid,$value);'
	if (@_ != 3);

    my $self=shift;
    my $mapid=shift;
    my $value=shift;

    my $mapinfo=$self->_mapinfo_lookup($mapid);
    if (!defined $mapinfo) {
	carp 'PhysicalMapWidget::set_minimum_feature_size: invalid $mapid';
	return;
    }

    $mapinfo->{minfeaturesize}=$value;


}

=item get_minimum_feature_size()

Returns the minimum size of the features being displayed.

Usage: $value=$widget->get_minimum_feature_size($mapid);

Returns: the minimum size of the displayed features (in base pairs).

=cut

sub get_minimum_feature_size {
    croak 'usage: $value=$widget->get_minimum_feature_size($mapid);'
	if (@_ != 2);

    my $self=shift;
    my $mapid=shift;

    my $mapinfo=$self->_mapinfo_lookup($mapid);
    if (!defined $mapinfo) {
	carp 'PhysicalMapWidget::get_minimum_feature_size: invalid $mapid';
	return;
    }

    return $mapinfo->{minfeaturesize};

}

sub get_sequence_display_threshold {
    my $self=shift;
    return $PhysicalMapWidget::sequence_display_threshold;
}

sub set_sequence_display_threshold {
    my $self=shift;
    my $thresh=shift;
    $PhysicalMapWidget::sequence_display_threshold=$thresh;
}


=item render()

Effectively lays out all the physical maps of the PhysicalMapWidget on its PaintDevice.

Usage: $widget->render()

=cut

sub render {
    croak 'usage: $widget->render();'
	if (@_ != 1);

    my $self = shift;

    my $x_offset=0;
    my $y_offset=0;

    $self->_compose_stripsets;

    foreach my $strip (@{$self->{stripsets}}) {
	$strip->draw($self->{paintdevice});
    }
    $self->{paintdevice}->render;
}



sub _compose_stripsets {
    my $self=shift;

    $self->{stripsets}=[];

    my $tot_lines=0;

    my $allstripsets=[];

    my $backgroundindex=0;

    foreach my $mapinfo (@{$self->{mapinfo}}) {
	my $mapstripsets=[];
	my $map=$mapinfo->{map};
	my $begin=$mapinfo->{begin};
	my $end=$mapinfo->{end};
	my $step=$mapinfo->{step};
	my $minfeaturesize=$mapinfo->{minfeaturesize};
	my $stripsets=int(($end-$begin+1)/$step);
	my $stripset_begin=$begin;
	my $stripset_end=$stripset_begin+$step-1;
	for  (my $s=0;$s<$stripsets;$s++) {
	    my $stripset=new PhysicalMapStripSet($map,$stripset_begin,
						 $stripset_end);
	    my $backgroundcolor=$self->{backgroundcolors}->[$backgroundindex];
	    $stripset->set_background_color($backgroundcolor);
	    my @features=$map->extract_features($stripset_begin,
						$stripset_end,
						$minfeaturesize);
	    for (my $i=0;$i<=$#features;$i++) {
		my $widget=FeatureWidgetFactory::get_widget_instance($features[$i]);
		$stripset->add_feature_widget($widget)
		    if (defined $widget);
	    }

	    my @companalres=$map->extract_companal_results($stripset_begin,
						   $stripset_end);
	    for (my $i=0;$i<=$#companalres;$i++) {
		my ($res_start,$res_end)=$companalres[$i]->bounds();
		my $type=$companalres[$i]->type();
		my $widget=CompAnalResultWidgetFactory::get_widget_instance($companalres[$i]);
		$stripset->add_companal_result_widget($widget)
		    if (defined $widget);
	    }

	    $tot_lines+=$stripset->height_in_lines;
	    push @{$mapstripsets},$stripset;
	    $stripset_begin=$stripset_end+1;
	    $stripset_end=$stripset_begin+$step-1;
	}
	push @{$allstripsets},$mapstripsets;
	$backgroundindex++;
	$backgroundindex=$backgroundindex % ($#{$self->{backgroundcolors}}+1);
    }

    my $stripsetindex=0;
    my $remaining=1;
    while ($remaining) {
	$remaining=0;
	foreach my $mapstripset (@{$allstripsets}) {
	    if (defined $mapstripset->[$stripsetindex]) {
		$remaining=1;
		push @{$self->{stripsets}},$mapstripset->[$stripsetindex];
	    }
	}
	$stripsetindex++;
    }

    my $cur_y=0;
    my $cur_x=0;
    my $textheight=$self->{paintdevice}->text_height;
    my $totheight=$tot_lines*$textheight*1.1;
    my $width=$self->{paintdevice}->width;

    $self->{paintdevice}->clear;
    $self->{paintdevice}->resize($width,$totheight);

    foreach my $stripset (@{$self->{stripsets}}) {
	my $strip_height=$stripset->height_in_lines/$tot_lines;
	$stripset->area($cur_x+0.02,$cur_y,0.96,$strip_height);
	$cur_y+=$strip_height;
    }
}

sub _mapinfo_lookup {
    my $self=shift;
    my $mapid=shift;
    my $resmapinfo=undef;

    foreach my $mapinfo (@{$self->{mapinfo}}) {
	$resmapinfo=$mapinfo
	    if ($mapid == $mapinfo->{mapid});
    }

    return $resmapinfo;

}

sub _mapindex_lookup {
    my $self=shift;
    my $mapid=shift;
    my $pos=-1;

    my $index=0;
    foreach my $mapinfo (@{$self->{mapinfo}}) {
	if ($mapid == $mapinfo->{mapid}) {
	    $pos=$index;
	}
	$index++;
    }

    return $pos;
}

=back

=head1 SEE ALSO

CompAnalResultWidget, FeatureWidget, PaintDevice, PhysicalMap, PhysicalMapStripSet.

=cut 

1
